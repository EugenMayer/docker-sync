#lib = File.expand_path('./lib', __dir__)
$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)

thor = File.expand_path('../tasks', __FILE__)
Dir.glob(File.join(thor, '/**/*.thor')).each { |taskfile|
  load taskfile
}
