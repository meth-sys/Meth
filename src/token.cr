module Meth
  # Types of tokens
  enum TokenType
    Keyword    # see KEYWORDS Const
    Identifier # Names
    Colon      # :
    Comma      # ,
    LParen     # (
    RParen     # )
    Number     # 0..9
    String     # "Hello, world"
    Char       # 'A'...
    Type       # Standard Typed, See TYPES Const
    Unknown    # Unknown???
    Eof        # \0, end
  end

  # Meth Keyword
  KEYWORDS = ["fun", "end", "return", "extern"]

  # Meth Types
  TYPES = [
    "bool", "char",
    "i8", "i16", "i32", "i64", "i128",
    "f16", "f32", "f64", "f128",
  ]

  # Represents a Token of code
  record Token,
    type : TokenType,
    value : String,
    line : UInt32,
    col : UInt32
end
