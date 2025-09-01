require "./codegen.cr"
require "./lexer.cr"
require "./parser.cr"

module Meth
  extend self
  VERSION = "0.1.0"

  keep = false
  filename = ""

  # Process ARGV
  if ARGV.empty?
    puts "Usage: meth [--keep|-k] <file>"
    exit 1
  end

  ARGV.each do |arg|
    case arg
    when "-k", "--keep"
      keep = true
    else
      if filename.empty?
        filename = arg
      else
        puts "Unexpected argument: #{arg}"
        exit 1
      end
    end
  end

  if filename.empty?
    puts "Usage: meth [--keep|-k] <file>"
    exit 1
  end

  # read the file
  content = ""
  File.open(filename) do |file|
    content = file.gets_to_end
  end

  # lex
  lexer = Lexer.new(content)
  tokens = lexer.lex

  # parse
  parser = Parser.new(tokens)
  nodes = parser.parse

  nodes.each do |n|
    puts n.to_s
  end

  LLVM.init_native_target

  context = LLVM::Context.new
  generator = CodeGenerator.new(context, "main")
  mod = generator.gen(nodes)

  # files
  llvmir_out = filename.sub(/\.\w+$/, ".ll")
  asm_out = filename.sub(/\.\w+$/, ".s")
  exec_out = filename.sub(/\.\w+$/, "")

  # generate IR and write to file
  File.open(llvmir_out, "w") do |f|
    mod.to_s(f)
  end

  # compile IR to Assembly
  unless system("llc #{llvmir_out}")
    puts "Failed to compile LLVM IR with LLC"
    exit 1
  end

  # compile final executable with gcc
  unless system("gcc -fsanitize=address -g #{asm_out} -o #{exec_out}")
    puts "Failed to compile Assembly to Executable."
    exit 1
  end

  # cleanup
  File.delete(llvmir_out) unless keep
  File.delete(asm_out) unless keep
end
