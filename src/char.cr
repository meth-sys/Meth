module Meth
  module Util
    extend self

    # Returns true if char is 0..9
    # else return false
    def is_digit(char)
      char >= '0' && char <= '9'
    end

    # Returns true if char is a..z or A..Z
    # else return false
    def is_letter(char)
      (char >= 'a' && char <= 'z') || (char >= 'A' && char <= 'Z')
    end

    # Returns true if char is letter, digit or _
    # else return false
    def is_word_char(char)
      is_letter(char) || is_digit(char) || char == '_' || char == '*'
    end

    # Returns true if char ' ', \t, \n or \r
    # else return false
    def is_whitespace(char)
      char == ' ' || char == '\t' || char == '\n' || char == '\r'
    end
  end
end
