require 'docker-sync/environment'
Dir[
  File.join(File.dirname(__FILE__), "docker-sync", "dependencies", "**", "*.rb")
].each { |f| require f }
require 'docker-sync/config/config_locator'
require 'docker-sync/config/global_config'
require 'docker-sync/config/project_config'
require 'docker-sync/preconditions/strategy'
