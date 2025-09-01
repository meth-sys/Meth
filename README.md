# Meth

  Meth is a tiny programming language written in Crystal using LLVM for learning purpose.  

## Development

  I intend to continue this language, but not alone, so if you are interested and want to continue it with me, contact me.  
## Hello, world

```
extern fun puts(value: char*): i64

fun main(): i32
  puts("Hello, world")
  return 0
end
```

## Status
* They are in order of priority

- [X] Functions
- [X] Extern Functions
- [X] Function Calls
- [X] Variables
- [ ] Conditionals
- [ ] Loops
- [ ] Argc Argv
- [ ] Structs
- [ ] Standard Library

## About Standard Library
  Well, if you take a look at the language, you noticed that the types are almost the same as in C language  
  We have pointers, and uses char* for strings  
  Maybe you're curious, why didn't I make a String type? an Array Type?  
  When the language evolves, when I add structs, and create the standard library, it will have types like Array and String  
  I want to avoid having to create things in the compiler as much as possible so as not to make future rewriting difficult.  
  If you stop to think, if I created an Array or String type, every compiler or interpreter created by anyone would have to implement them, but if I write these types in the language itself, and implement only low-level things in the compiler/interpreter, it is easier.  

## Community
[![Join our Discord server!](https://invidget.switchblade.xyz/5hSStgYfru)](https://discord.gg/5hSStgYfru)

## Contributing

1. Fork it (<https://github.com/trindadedev13/meth/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [trindadedev13](https://github.com/trindadedev13) - creator and maintainer
