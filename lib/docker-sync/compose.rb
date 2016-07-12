require 'docker/compose'

class ComposeManager
  include Thor::Shell
  @compose_session
  @global_options
  def initialize(global_options)
    @global_options = global_options
    compose_file_path = 'docker-compose.yml'
    if @global_options.key?('compose-file-path')
      path = File.expand_path(@global_options['compose-file-path'])
      unless File.exist?(path)
        raise("Your referenced docker-compose file in docker-sync.yml was not found at #{@global_options['compose-file-path']}")
      end
      compose_file_path = @global_options['compose-file-path']
    end
    @compose_session = Docker::Compose::Session.new(dir:'./', :file => compose_file_path)
  end

  def run
    say_status 'ok','starting compose',:white
    @compose_session.up
    say_status 'success','started compose',:green
  end

  def stop
    @compose_session.stop
  end

  def clean
    @compose_session.down
  end
end