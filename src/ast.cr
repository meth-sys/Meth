module Meth
  module Ast
    # Base class for nodes
    abstract class Node
      abstract def fmt_with_indent(indent = 0) : String

      def to_s
        fmt_with_indent
      end

      protected def pad(indent)
        "  " * indent
      end
    end

    # Represents a Meth Literal
    #
    # @type  : The type of literal
    # @value : The value of literal
    class LiteralNode(T) < Node
      property type : T.class
      property value : T

      def initialize(@value : T)
        @type = value.class
      end

      def fmt_with_indent(indent = 0) : String
        c = self.class.name
        "#{pad(indent)}#{c}: #{value.inspect}"
      end
    end

    # Represents a Meth Function Patam
    #
    # @name : The name of param
    # @name : The expected type of param
    class ParamNode < Node
      property name : String
      property type : String

      def initialize(@name, @type)
      end

      def fmt_with_indent(indent = 0) : String
        "#{pad(indent)}Param: #{name}: #{type}"
      end
    end

    # Represents a Meth Function GENERIC Param
    #
    # @name         : The name of param
    # @type         : The expected type of param
    # @gereric_type : The type of generic
    class GenericParamNode < Node
      property name : String
      property type : String
      property generic_type : String

      def initialize(@name, @type, @generic_type)
      end

      def fmt_with_indent(indent = 0) : String
        "#{pad(indent)}GenericParam: #{name}: #{type}(#{generic_type})"
      end
    end

    # FunctionNode
    #
    # Represents a Meth function
    # @name        : The name of fun
    # @return_type : The return type (like i32)
    # @params      : The parameters of functions
    # @body        : The body nodes of a function, shouldn't be a Function!
    # @extern      : Indicates if the function is extern (just declaration)
    class FunctionNode < Node
      property name : String
      property return_type : String
      property params : Array(ParamNode | GenericParamNode)
      property body : Array(Node)
      property extern : Bool

      def initialize(@name, @return_type, @params, @body, @extern = false)
      end

      def fmt_with_indent(indent = 0) : String
        output = "#{pad(indent)}Function: #{name}\n"
        output += "#{pad(indent + 1)}ReturnType: #{return_type}\n"
        output += "#{pad(indent + 1)}Extern: #{extern}\n"
        output += "#{pad(indent + 1)}Params:\n"
        output += params.map { |p| p.fmt_with_indent(indent + 2) }.join("\n") + "\n"
        output += "#{pad(indent + 1)}Body:\n"
        output += body.map { |b| b.fmt_with_indent(indent + 2) }.join("\n")
        output
      end
    end

    # Represents a return statement
    #
    # @value : The return value
    class ReturnNode < Node
      property value : Node?

      def initialize(@value)
      end

      def fmt_with_indent(indent = 0) : String
        val_str = value.try &.fmt_with_indent(indent + 1) || "#{pad(indent + 1)}nil"
        "#{pad(indent)}Return:\n#{val_str}"
      end
    end

    # Represents a variable declaration
    #
    # @name  : The name of var
    # @type  : The type of var
    # @value  : The value of var
    class VarDeclNode(T) < Node
      property name : String
      property type : String
      property value : T

      def initialize(@name, @type, @value)
      end

      def fmt_with_indent(indent = 0) : String
        "#{pad(indent)}VarDecl: #{name}: #{type} = #{value.to_s}"
      end
    end

    # Represents a Meth Function Call
    #
    # @name : The name of function to call
    # @args : The arguments to the function
    class CallNode < Node
      property name : String
      property args : Array(Node)

      def initialize(@name, @args)
      end

      def fmt_with_indent(indent = 0) : String
        output = "#{pad(indent)}Call: #{name}"
        output += args.map { |a| "\n" + a.fmt_with_indent(indent + 1) }.join
        output
      end
    end

    # Represents a Reference to a variable
    #
    # @name : The name of referenced variavle
    class VarRefNode < Node
      property name : String

      def initialize(@name)
      end

      def fmt_with_indent(indent = 0) : String
        "#{pad(indent)}VarRef: #{name}"
      end
    end
  end
end
