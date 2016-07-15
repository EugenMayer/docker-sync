file = File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__
file = File.expand_path(File.dirname(file))
$LOAD_PATH.unshift File.expand_path('./lib', file)
thor = File.expand_path('./tasks', file)

Dir.glob(File.join(thor, '/**/*.thor')).each { |taskfile|
  load taskfile
}
