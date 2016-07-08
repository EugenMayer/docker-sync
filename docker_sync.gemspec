Gem::Specification.new do |s|
  s.name        = 'docker_sync'
  s.version     = '0.0.2'
  s.date        = '2016-07-08'
  s.summary     = 'Docker Sync - Fast and efficient way to sync code to docker-containers'
  s.description = 'Sync your code live to docker-containers without losing any performance on OSX'
  s.authors     = ['Eugen Mayer']
  s.executables = %w[docker-sync]
  s.email       = 'eugen.mayer@kontextwork.de'
  s.files       = Dir['lib/**/*.rb','tasks/**/*.thor','Thorfile','bin/*']
  s.license     = 'GPL'
  s.homepage    = 'https://github.com/EugenMayer/docker_registry_cli'
  s.add_runtime_dependency 'colorize', '~> 0'
  s.add_runtime_dependency 'httparty', '~> 0'
end
