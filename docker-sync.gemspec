Gem::Specification.new do |s|
  s.name        = 'docker-sync'
  s.version     = File.read("VERSION")
  s.summary     = 'Docker Sync - Fast and efficient way to sync code to docker-containers'
  s.description = 'Sync your code live to docker-containers without losing any performance on OSX'
  s.authors     = ['Eugen Mayer']
  s.executables = %w[docker-sync docker-sync-stack]
  s.email       = 'eugen.mayer@kontextwork.de'
  s.files       = Dir['lib/**/*.rb','tasks/**/*.thor','Thorfile','bin/*','VERSION']
  s.license     = 'GPL'
  s.homepage    = 'https://github.com/EugenMayer/docker_sync'
  s.required_ruby_version = '>= 2.0'
  s.add_runtime_dependency 'thor', '~> 0.19', '>= 0.19.0'
  s.add_runtime_dependency 'gem_update_checker', '~> 0.2.0', '>= 0.2.0'
  s.add_runtime_dependency 'docker-compose', '0.8.3'
  s.add_runtime_dependency 'terminal-notifier', '1.6.3'
end
