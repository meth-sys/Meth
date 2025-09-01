require "./ast.cr"
require "./token.cr"

module Meth
  class Parser
    @tokens : Array(Token)
    @pos : UInt32

    def initialize(tokens)
      @tokens = tokens
      @pos = 0
    end

    # returns the current token
    # raise if out of bounds.
    def current_token
      raise "Unexpected end of input at position #{@pos}" if @pos >= @tokens.size
      @tokens[@pos]
    end

    # returns the next token without advance
    # raise if out of bounds.
    def next_token
      raise "Unexpected end of input at position #{@pos + 1}" if (@pos + 1) >= @tokens.size
      @tokens[@pos + 1]
    end

    # advance if not out of bounds
    # returns current_token
    def advance
      if @pos < @tokens.size
        @pos += 1
      end
      current_token
    end

    # returns the current token and advance
    def consume
      token = current_token
      advance
      token
    end

    # returns the token if the type is the same as expected
    # else raise a error
    def expect(type)
      token = current_token
      if token.type == type
        advance
        token
      else
        raise "[Error #{token.line}:#{token.col}]: Expected type '#{type}' got '#{token.type}'."
      end
    end

    # FIXME!!: DOCUMENT THIS FUNCTION
    def parse_fun_params
      expect(TokenType::LParen)
      params = [] of Ast::ParamNode | Ast::GenericParamNode
      until current_token.type == TokenType::RParen
        param_name = expect(TokenType::Identifier).value
        expect(TokenType::Colon)

        param_type = ""
        generic_type = ""

        # parse the main type (Type or Identifier)
        if current_token.type == TokenType::Identifier || current_token.type == TokenType::Type
          param_type = expect(current_token.type).value
        else
          raise "Expected type or identifier for param type"
        end

        # check if it's a generic type, like Type(GenericType)
        if current_token.type == TokenType::LParen
          expect(TokenType::LParen)

          if current_token.type == TokenType::Identifier || current_token.type == TokenType::Type
            generic_type = expect(current_token.type).value
          else
            raise "Expected type or identifier for generic type"
          end

          expect(TokenType::RParen)
        end

        if generic_type.empty?
          params << Ast::ParamNode.new(param_name, param_type)
        else
          params << Ast::GenericParamNode.new(param_name, param_type, generic_type)
        end

        break if current_token.type == TokenType::RParen
        expect(TokenType::Comma)
      end
      expect(TokenType::RParen)
      params
    end

    # FIXME!!: DOCUMENT THIS FUNCTION
    def parse_fun_ret_type
      return_type = "void"
      if current_token.type == TokenType::Colon
        advance
        if current_token.type == TokenType::Identifier
          return_type = expect(TokenType::Identifier).value
        elsif current_token.type == TokenType::Type
          return_type = expect(TokenType::Type).value
        end
      end
      return_type
    end

    # FIXME!!: DOCUMENT THIS FUNCTION
    def parse_fun_body
      body = [] of Ast::Node
      while !(current_token.type == TokenType::Keyword && current_token.value == "end")
        stmt = parse_statement
        body << stmt if stmt
      end
      body
    end

    # FIXME!!: DOCUMENT THIS FUNCTION
    def parse_fun
      k_token = expect(TokenType::Keyword)
      raise "[Error #{k_token.line}:#{k_token.col}] Expected 'fun' keyword, got #{k_token.value}" if k_token.value != "fun"

      name = expect(TokenType::Identifier).value
      params = parse_fun_params
      return_type = parse_fun_ret_type
      body = parse_fun_body

      expect(TokenType::Keyword) # end

      Ast::FunctionNode.new(name, return_type, params, body)
    end

    # FIXME!!: DOCUMENT THIS FUNCTION
    def parse_extern_fun
      k_token = expect(TokenType::Keyword)
      raise "[Error #{k_token.line}:#{k_token.col}] Expected 'extern' keyword, got #{k_token.value}" if k_token.value != "extern"

      k_token = expect(TokenType::Keyword)
      raise "[Error #{k_token.line}:#{k_token.col}] Expected 'fun' keyword, got #{k_token.value}" if k_token.value != "fun"

      name = expect(TokenType::Identifier).value
      params = parse_fun_params
      return_type = parse_fun_ret_type

      Ast::FunctionNode.new(name, return_type, params, [] of Ast::Node, extern: true)
    end

    # FIXME!!: DOCUMENT THIS FUNCTION
    def parse_call(name : String)
      args = [] of Ast::Node

      if current_token.type == TokenType::LParen
        advance
        until current_token.type == TokenType::RParen
          args << parse_expression
          break if current_token.type == TokenType::RParen
          expect(TokenType::Comma)
        end
        expect(TokenType::RParen)
      end

      Ast::CallNode.new(name, args)
    end

    # FIXME!!: DOCUMENT THIS FUNCTION
    def parse_var_decl(type)
      name = expect(TokenType::Identifier).value
      expect(TokenType::Assign)
      value = parse_expression

      Ast::VarDeclNode.new(name, type, value)
    end

    # FIXME!!: DOCUMENT THIS FUNCTION
    def parse_expression
      case current_token.type
      when TokenType::String
        Ast::LiteralNode.new(expect(TokenType::String).value)
      when TokenType::Number
        Ast::LiteralNode.new(expect(TokenType::Number).value.to_i32)
      when TokenType::Char
        Ast::LiteralNode.new(expect(TokenType::Char).value.chars[0])
      when TokenType::Identifier
        name = expect(TokenType::Identifier).value
        if current_token.type == TokenType::LParen
          parse_call(name)
        else
          Ast::VarRefNode.new(name)
        end
      else
        raise "Unsupported expression at #{current_token}"
      end
    end

    # FIXME!!: DOCUMENT THIS FUNCTION
    def parse_return
      k_token = expect(TokenType::Keyword) # should be return
      raise "[Error #{k_token.line}:#{k_token.col}] Expected 'return' keyword, got #{k_token.value}" if k_token.value != "return"
      Ast::ReturnNode.new(parse_expression)
    end

    # FIXME!!: DOCUMENT THIS FUNCTION
    def parse_identifier
      id = expect(TokenType::Identifier).value
      if current_token.type == TokenType::Identifier
        if next_token.type == TokenType::Assign
          return parse_var_decl(id)
        end
      end
      parse_call(id)
    end

    # FIXME!!: DOCUMENT THIS FUNCTION
    def parse_type
      type = expect(TokenType::Type).value
      if current_token.type == TokenType::Identifier
        if next_token.type == TokenType::Assign
          parse_var_decl(type)
        end
      end
    end

    # FIXME!!: DOCUMENT THIS FUNCTION
    def parse_statement
      case current_token.type
      when TokenType::Keyword
        if current_token.value == "fun"
          parse_fun
        elsif current_token.value == "extern"
          if next_token.type == TokenType::Keyword && next_token.value == "fun"
            parse_extern_fun
          end
        elsif current_token.value == "return"
          parse_return
        else
          advance
          nil
        end
      when TokenType::Type
        parse_type
      when TokenType::Identifier
        parse_identifier
      else
        advance
        nil
      end
    end

    # FIXME!!: DOCUMENT THIS FUNCTION
    def parse
      nodes = [] of Ast::Node

      while current_token.type != TokenType::Eof
        node = parse_statement
        nodes << node if node
      end

      nodes
    end
  end
end
