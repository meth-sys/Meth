require "./codegen.cr"
require "./lexer.cr"
require "./parser.cr"

module Meth
  extend self
  VERSION = "0.1.0"

  # read the file passed by stdout
  puts "Usage: meth main.mh" if ARGV.size != 1
  content = ""
  File.open(ARGV[0]) do |file|
    content = file.gets_to_end
  end

  # lex
  lexer = Lexer.new(content)
  tokens = lexer.lex

  # parse
  parser = Parser.new(tokens)
  nodes = parser.parse

  LLVM.init_native_target

  context = LLVM::Context.new
  generator = CodeGenerator.new(context, "main")
  mod = generator.gen(nodes)

  # files
  llvmir_out = ARGV[0].sub(".mh", ".ll")
  asm_out = ARGV[0].sub(".mh", ".s")
  exec_out = ARGV[0].sub(".mh", "")

  # generate IR and write to file
  File.open(llvmir_out, "w") do |f|
    mod.to_s(f)
  end

  # compile IR to Assembly
  llc_status = system("llc #{llvmir_out}")
  if !llc_status
    puts "Failed to compile LLVM IR with LLC"
    abort
  end

  # compile final executable with gcc
  gcc_status = system("gcc #{asm_out} -o #{exec_out}")
  if !gcc_status
    puts "Failed to compile Assembly to Executable."
    abort
  end

  # cleanup
  File.delete(llvmir_out)
  File.delete(asm_out)
end
