require "llvm"
require "./ast.cr"

module Meth
  class CodeGenerator
    @context : LLVM::Context
    @module : LLVM::Module
    @builder : LLVM::Builder
    @function_types = Hash(String, LLVM::Type).new

    def initialize(@context, mod_name : String)
      @module = @context.new_module(mod_name)
      @builder = @context.new_builder
    end

    def gen(nodes : Array(Ast::Node))
      nodes.each do |node|
        declare_fun(node) if node.is_a?(Ast::FunctionNode)
      end
      nodes.each do |node|
        gen_fun(node) if node.is_a?(Ast::FunctionNode) && !node.extern
      end
      @module
    end

    def get_llvm_type_from_meth(meth : String) : LLVM::Type
      # pointers, count the * in end
      ptr_depth = meth.count('*')
      base_type_str = meth.rstrip('*').strip

      # Trata arrays fixos, tipo "i32[10]"
      # fixed arrays like i32[10]
      if base_type_str =~ /(.*)\[(\d+)\]$/
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

    def declare_fun(fn : Ast::FunctionNode)
      return if @module.functions[fn.name]?
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

    def gen_fun(fn : Ast::FunctionNode)
      func = @module.functions[fn.name]

      block = func.basic_blocks.append("entry")
      @builder.position_at_end(block)

      # named params
      fn.params.each_with_index do |param, i|
        if param.is_a?(Ast::ParamNode)
          func.params[i].name = param.name
        end
      end

      fn.body.each do |stmt|
        gen_stmt(stmt)
      end

      if fn.return_type == "void" && !ends_with_return?(fn.body)
        @builder.ret
      end
    end

    def ends_with_return?(body)
      last = body.last?
      last.is_a?(Ast::ReturnNode)
    end

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
      else
        raise "Unhandled statement: #{node}"
      end
    end

    def gen_expr(node)
      case node
      when Ast::LiteralNode(Int32)
        @context.int32.const_int(node.value)
      when Ast::LiteralNode(String)
        str = node.value
        global_str = @builder.global_string_pointer(str, "str")
        @builder.bit_cast(global_str, @context.int8.pointer)
      when Ast::LiteralNode(Char)
        @context.int8.const_int(node.value.ord)
      else
        raise "Unhandled expr: #{node.class}"
      end
    end

    def gen_call(node)
      if func_type = @function_types[node.name]
        func = @module.functions[node.name]
        args = node.args.map do |arg|
          gen_expr(arg)
        end
        @builder.call(func_type, func, args)
      else
        raise "Unknown function call: #{node.name}"
      end
    end
  end
end
