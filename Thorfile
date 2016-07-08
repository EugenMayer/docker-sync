lib = File.expand_path('./lib', __dir__)
thor = File.expand_path('./thor', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)


Dir.glob(File.join(thor, '/**/*.thor')).each { |taskfile|
  load taskfile
}
