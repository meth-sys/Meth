require "./char.cr"
require "./token.cr"

module Meth
  class Lexer
    @src : String
    @pos : UInt32
    @line : UInt32
    @col : UInt32

    def initialize(input)
      @src = input
      @pos = 0
      @line = 1
      @col = 1
    end

    private def advance
      if current_char
        if current_char == '\n'
          @line += 1
          @col = 1
        else
          @col += 1
        end
        @pos += 1
      end
    end

    private def skip_whitespace
      while current_char && Util.is_whitespace(current_char.not_nil!)
        advance
      end
    end

    private def current_char
      @pos < @src.size ? @src[@pos] : nil
    end

    private def make_token(*args)
      Token.new(*args, @line, @col)
    end

    private def number
      num = ""
      while current_char && Util.is_digit(current_char.not_nil!)
        num += current_char.not_nil!
        advance
      end
      make_token(TokenType::Number, num)
    end

    private def word
      w = ""
      while current_char && Util.is_word_char(current_char.not_nil!)
        w += current_char.not_nil!
        advance
      end

      if KEYWORDS.includes?(w)
        make_token(TokenType::Keyword, w)
      elsif TYPES.includes?(w)
        make_token(TokenType::Type, w)
      else
        make_token(TokenType::Identifier, w)
      end
    end

    private def string
      advance
      str = ""
      while current_char && current_char != '"'
        if current_char == '\\'
          advance
          str += case current_char.not_nil!
                 when 'n'  then '\n'
                 when 't'  then '\t'
                 when '"'  then '"'
                 when '\\' then '\\'
                 else           current_char.not_nil!
                 end
        else
          str += current_char.not_nil!
        end
        advance
      end
      advance
      make_token(TokenType::String, str)
    end

    private def char
      advance
      if current_char.nil?
        raise "Error[#{@line}:#{@col}]:Unterminated character literal"
      end
      value = ""
      if current_char == '\\'
        advance
        value = case current_char.not_nil!
                when 'n'  then '\n'
                when 't'  then '\t'
                when '"'  then '"'
                when '\\' then '\\'
                else           raise "Error[#{@line}:#{@col}]: Invalid escape sequence in character literal"
                end
      else
        value = current_char.not_nil!
      end
      advance
      if current_char != '\''
        raise "Error[#{@line}:#{@col}]: Unterminate or too long character literal."
      end
      advance
      make_token(TokenType::Char, value.to_s)
    end

    private def next_token
      skip_whitespace
      return nil if current_char.nil?

      ch = current_char.not_nil!

      if ch == '#'
        while current_char && current_char != '\n'
          advance
        end
        advance if current_char == '\n'
        return next_token
      end

      if Util.is_digit(ch)
        return number
      elsif Util.is_letter(ch) || ch == '_'
        return word
      elsif ch == '"'
        return string
      elsif ch == '\''
        return char
      end

      advance
      case ch
      when ':' then make_token(TokenType::Colon, ":")
      when '(' then make_token(TokenType::LParen, "(")
      when ')' then make_token(TokenType::RParen, ")")
      when ',' then make_token(TokenType::Comma, "'")
      when '=' then make_token(TokenType::Assign, "=")
      else          make_token(TokenType::Unknown, char.to_s)
      end
    end

    def lex
      tokens = [] of Token
      loop do
        token = next_token
        break if token.nil?
        tokens << token
      end
      tokens << make_token(TokenType::Eof, "")
      tokens
    end
  end
end
