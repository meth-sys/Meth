require "fileutils"

def run(cmd)
  puts "#{cmd}"
  system(cmd) or abort("#{cmd} failed!")
end

# Arguments
$option_build = false
$option_gdb = false
$option_run = false
$option_termux = false
$option_keep = false
$option_display_tokens = false
$option_display_ast = false
$option_link_flags = []
ARGV.each do |arg|
  case arg
    when "--build", "-b"
      $option_build = true
    when "--gdb", "-g"
      $option_gdb = true
    when "--run", "-r"
      $option_run = true
    when "--termux", "-t"
      $option_termux = true
    when "--keep", "-k"
      $option_keep = true
    when "-dt", "--display-tokens"
      $option_display_tokens = true
    when "-da", "--display-ast"
      $option_display_ast = true
    else
      if arg.start_with?("-")
        $option_link_flags << arg
      else
        puts "Unknown args #{arg}."
        exit 1
      end
  end
end

default_lib_paths = [
  "/system/lib64",
  "/apex/com.android.runtime/lib64/bionic"
]

$option_link_flags << default_lib_paths.flat_map do |p| ["-L#{p}"] end if $option_termux

HOME = ENV["HOME"]
$dest_dir = "#{HOME}/temp/crystal/meth"
$args = "test/main.mh"

$args << " --keep" if $option_keep
$args << " --display-tokens" if $option_display_tokens
$args << " --display-ast" if $option_display_ast
$args << " " << $option_link_flags.join(" ")

# Build
if $option_build
  if $option_termux
    FileUtils.mkdir_p($dest_dir)
  
    files = Dir.glob("**", File::FNM_DOTMATCH).reject { |f| f =~ /\A\.\.?\z/ }
  
    FileUtils.cp_r(files, $dest_dir, remove_destination: true)
    
    Dir.chdir($dest_dir) do
      # run("chmod -R u+x .")
      run("shards build")
    end
  else
    run("shards build")
  end
end

def run_program(dir = "./")
  executable = "#{dir}bin/meth"
  if $option_gdb
    run("gdb #{executable} --args #{executable} #{$args}")
  else
    run("#{executable} #{$args}")
  end
end

# Run
if $option_termux
  run_program("#{$dest_dir}/") if $option_run
else
  run_program() if $option_run
end