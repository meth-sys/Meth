require "llvm"
require "./ast.cr"

# Represents a LLVM Var
#
# @type  : The value type
# @value : The Value
# @is_pointer : Indicates if variable is pointer.
# * why we need known if var is pointer?
#  When getting var value, if it's a pointer we should load it value
#  else if it's not a pointer, we can just return it's value.
class LLVMVariable
  property type : LLVM::Type
  property value : LLVM::Value
  property is_pointer : Bool

  def initialize(@type, @value, @is_pointer = false)
  end

  def to_s
    "LLVMVariable: #{type}#{is_pointer ? "*" : ""} = #{value}"
  end
end

module Meth
  class CodeGenerator
    @context : LLVM::Context
    @module : LLVM::Module
    @builder : LLVM::Builder
    @function_types = Hash(String, LLVM::Type).new
    @variables = Hash(String, LLVMVariable).new

    def initialize(@context, mod_name : String)
      @module = @context.new_module(mod_name)
      @builder = @context.new_builder
    end

    # generates the LLVM-IR and Returns the Module
    def gen(nodes : Array(Ast::Node)) : LLVM::Module
      # first we declare all functions
      nodes.each do |node|
        declare_fun(node) if node.is_a?(Ast::FunctionNode)
      end
      # now we gen full function with body, except by extern functions
      nodes.each do |node|
        gen_fun(node) if node.is_a?(Ast::FunctionNode) && !node.extern
      end
      @module
    end

    # returns the LLVM type based on Meth Type
    #
    # example: i32 => @context.i32
    def get_llvm_type_from_meth(meth : String) : LLVM::Type
      # pointers, count the * in end
      ptr_depth = meth.count('*')
      base_type_str = meth.rstrip('*').strip

      # fixed arrays like i32[10]
      if base_type_str =~ /(.*)(\d+)$/
        base_type_str = $1
        array_size = $2.to_i
        base_type = get_llvm_type_from_meth(base_type_str)
        ty = base_type.array(array_size)
      else
        ty = case base_type_str
             when "void" then @context.void
             when "bool" then @context.int1
             when "char" then @context.int8
               # int
             when "i8"   then @context.int8
             when "i16"  then @context.int16
             when "i32"  then @context.int32
             when "i64"  then @context.int64
             when "i128" then @context.int128
               # float
             when "f16"  then @context.half
             when "f32"  then @context.float
             when "f64"  then @context.double
             when "f128" then @context.fp128
             else             raise "Unknown base type: #{base_type_str}"
             end
      end

      # apply pointers
      ptr_depth.times do
        ty = ty.pointer
      end

      ty
    end

    # declarates a function in IR
    #
    # ```
    #  FunctionNode(
    #    name: print,
    #    return_type: i32,
    #    params: [void*, i64],
    #    body: []
    #  ) => declare i32 @print(ptr, i64)
    # ```
    def declare_fun(fn : Ast::FunctionNode)
      raise "Redeclaration of #{fn.name}" if @module.functions[fn.name]?
      return_type = get_llvm_type_from_meth(fn.return_type)
      arg_types = fn.params.map do |p|
        case p
        when Ast::ParamNode        then get_llvm_type_from_meth(p.type)
        when Ast::GenericParamNode then get_llvm_type_from_meth(p.generic_type)
        end
      end.compact

      func_type = LLVM::Type.function(arg_types, return_type)
      @function_types[fn.name] = func_type
      @module.functions.add(fn.name, func_type)
    end

    # generates a function entry in IR
    #
    # ```
    #  FunctionNode(
    #    name: print,
    #    return_type: i32,
    #    params: [void*, i64],
    #    body: []
    #  ) =>
    #  define void @print(ptr %0, i64 %1) {
    #  entry:
    #    ...
    #  }
    # ```
    def gen_fun(fn : Ast::FunctionNode)
      func = @module.functions[fn.name]
      block = func.basic_blocks.append("entry")
      @builder.position_at_end(block)

      fn.params.each_with_index do |param, i|
        if param.is_a?(Ast::ParamNode)
          param_type = get_llvm_type_from_meth(param.type)
          @variables[param.name] = LLVMVariable.new(param_type, func.params[i])
        end
      end

      fn.body.each do |stmt|
        gen_stmt(stmt)
      end

      if fn.return_type == "void" && !ends_with_return?(fn.body)
        @builder.ret
      end
    end

    # returns the var in IR
    #
    # if var is a pointer it'll generate something like:
    # ```
    # %hello1 = load ptr, ptr %hello, align 8
    # ```
    # %hello1 is the loaded var
    # %hello is the raw ptr
    # it's like :
    # const char** hello = ...;
    # const char* hello1 = *hello;
    #
    # else if it's not a var, we can return the raw value
    # cause it's already the value.
    #
    def get_var(name)
      var = @variables[name]
      raise "Variable #{name} not exists." if var.nil?
      if var.is_pointer
        @builder.load(var.type, var.value, name)
      else
        var.value
      end
    end

    # generates a expression for IR
    #
    # it basically translates the Meth value to LLVM Value
    #
    # ```
    # Ast::LiteralNode(5) => @context.int32.const_int(5)
    # ```
    def gen_expr(node)
      case node
      when Ast::LiteralNode(Int32)
        @context.int32.const_int(node.value)
      when Ast::LiteralNode(Int64)
        @context.int64.const_int(node.value)
      when Ast::LiteralNode(String)
        str = node.value
        global_str = @module.globals.add(@context.int8.array(str.bytesize + 1), "str")
        global_str.initializer = @context.const_string(str)
        global_str.linkage = LLVM::Linkage::Private
        global_str.global_constant = true
        @builder.bit_cast(global_str, @context.int8.pointer)
      when Ast::LiteralNode(Char)
        @context.int8.const_int(node.value.ord)
      when Ast::VarRefNode
        get_var(node.name)
      else
        raise "Unhandled expr: #{node.class}"
      end
    end

    # generates a function call in IR
    #
    # ```
    # Ast::CallNode(
    #  "print",
    #  [Ast::LiteralNode("hello"), Ast::LiteralNode(5)]
    # ) => call void @print(ptr @str, i64 5)
    # ```
    #
    # * Note that `ptr @str` is a ref to hello string.
    def gen_call(node : Ast::CallNode)
      if func_type = @function_types[node.name]
        func = @module.functions[node.name]
        args = node.args.map_with_index do |arg, i|
          value = gen_expr(arg)
          expected_type = func_type.params_types[i]

          if value.type != expected_type && value.type.kind == LLVM::Type::Kind::Integer && expected_type.kind == LLVM::Type::Kind::Integer
            @builder.zext(value, expected_type)
          else
            value
          end
        end
        @builder.call(func_type, func, args)
      else
        raise "Unknown function: #{node.name}"
      end
    end

    # generates a var decl in IR
    #
    # ```
    # Ast::VarDeclNode(
    #  "hello",
    #  "char*",
    #  "Hello"
    # ) =>
    # %hello = alloca ptr, align 8
    # store ptr @str, ptr %hello, align 8
    # ```
    #
    # another example without pointer:
    # ```
    # %age = alloca i32, align 4
    # store i32 14, ptr %age, align 4
    # ```
    def gen_var(node : Ast::VarDeclNode)
      value = gen_expr(node.value)
      var_type = get_llvm_type_from_meth(node.type)

      if value.type != var_type && value.type.kind == LLVM::Type::Kind::Integer && var_type.kind == LLVM::Type::Kind::Integer
        value = @builder.zext(value, var_type)
      end

      alloca = @builder.alloca(var_type, node.name)
      @builder.store(value, alloca)
      @variables[node.name] = LLVMVariable.new(var_type, alloca, is_pointer: true)
    end

    # check if function ends with return statement
    def ends_with_return?(body)
      last = body.last?
      last.is_a?(Ast::ReturnNode)
    end

    # generates a statement in IR
    #
    # Ast::ReturnNode => @builder.ret
    # Ast::ReturnNode(Ast::LiteralNode(5)) => @builder.ret(gen_expr(Ast::LiteralNode(5)))
    #
    # Ast::CallNode => gen_call
    # Ast::VarDeclNode => node
    def gen_stmt(node)
      case node
      when Ast::ReturnNode
        if val = node.value
          value = gen_expr(val)
          @builder.ret(value)
        else
          @builder.ret
        end
      when Ast::CallNode
        gen_call(node)
      when Ast::VarDeclNode
        gen_var(node)
      else
        raise "Unhandled statement: #{node}"
      end
    end
  end
end
