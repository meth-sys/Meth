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
  end
end

HOME = ENV["HOME"]
$dest_dir = "#{HOME}/temp/crystal/meth"
$args = "test/main.mh"
if $option_keep
  $args << " --keep"
end

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