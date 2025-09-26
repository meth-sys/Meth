require "./codegen.cr"
require "./lexer.cr"
require "./parser.cr"

module Meth
  extend self
  VERSION = "0.1.0"

  filename = ""

  # Process ARGV
  if ARGV.empty?
    puts "Usage: meth [--keep|-k] <file>"
    exit 1
  end

  keep = false
  display_tokens = false
  display_ast = false
  link_args = [] of String

  ARGV.each do |arg|
    case arg
    when "-dt", "--display-tokens"
      display_tokens = true
    when "-da", "--display-ast"
      display_ast = true
    when "-k", "--keep"
      keep = true
    else
      if filename.empty?
        filename = arg
      else
        if arg.starts_with?("-")
          link_args << arg
        else
          puts "Unexpected argument: #{arg}"
          exit 1
        end
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
  if display_tokens
    tokens.each do |t|
      puts t.to_s
    end
  end

  # parse
  parser = Parser.new(tokens)
  nodes = parser.parse

  if display_ast
    nodes.each do |n|
      puts n.to_s
    end
  end

  LLVM.init_native_target

  context = LLVM::Context.new
  generator = CodeGenerator.new(context, "main")
  mod = generator.gen(nodes)

  # files
  llvmir_out = filename.sub(/\.\w+$/, ".ll")
  obj_out = filename.sub(/\.\w+$/, ".o")
  exec_out = filename.sub(/\.\w+$/, "")

  # generate IR and write to file
  File.open(llvmir_out, "w") do |f|
    mod.to_s(f)
  end

  # compile IR to Obj
  unless system("llc #{llvmir_out} --filetype=obj")
    puts "Failed to compile LLVM IR with LLC"
    exit 1
  end

  # Link Obj
  link_cmd = ["ld.lld", obj_out, "-o", exec_out] + link_args
  unless system(link_cmd.join(" "))
    puts "Failed to link Object to Executable."
    exit 1
  end

  # cleanup
  File.delete(llvmir_out) unless keep
  File.delete(obj_out) unless keep
end
