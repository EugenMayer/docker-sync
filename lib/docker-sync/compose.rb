require 'docker/compose'
require 'pp'
class ComposeManager
  include Thor::Shell
  @compose_session
  @global_options
  def initialize(global_options)
    @global_options = global_options

    ### production docker-compose.yml
    compose_files = [File.expand_path('docker-compose.yml')]
    if @global_options.key?('compose-file-path')
      compose_files = [] # replace
      apply_path_settings(compose_files, @global_options['compose-file-path'], 'compose-file-path')
    end

    ### development docker-compose-dev.yml
    if @global_options.key?('compose-dev-file-path')
      # explicit path given
      apply_path_settings(compose_files, @global_options['compose-dev-file-path'], 'compose-dev-file-path')
      say_status 'ok',"Found explicit docker-compose-dev.yml and using it from #{@global_options['compose-dev-file-path']}", :green
    else
      # try to find docker-compose-dev.yml
      e = compose_files.to_enum
      production_compose_file = File.expand_path(e.peek)
      working_dir = File.dirname(production_compose_file)
      compose_dev_path = "#{working_dir}/docker-compose-dev.yml"
      if File.exist?(compose_dev_path)
        say_status 'ok',"Found implicit docker-compose-dev.yml and using it from #{compose_dev_path}", :green
        compose_files.push compose_dev_path
      end
    end
    @compose_session = Docker::Compose::Session.new(dir:'./', :file => compose_files)
  end

  def run
    say_status 'ok','starting compose',:green
    options = Hash.new
    if @global_options['compose-force-build']
      options[:build] = true
    end
    @compose_session.up(**options)
  end

  def stop
    @compose_session.stop
  end

  def clean
    @compose_session.down
  end

  protected
    def apply_path_settings(compose_files, settings, error_key)
      if settings.kind_of?(Array)
        apply_filepaths(compose_files, settings, error_key)
      else
        apply_filepath(compose_files, settings, error_key)
      end
    end

  private
    def apply_filepath(array, filepath, error_key)
      path = File.expand_path(filepath)
      unless File.exist?(path)
        raise("Your referenced docker-compose file in docker-sync.yml was not found at #{error_key}")
      end
      array.push path
    end

    def apply_filepaths(array, filepath_array, error_key)
      filepath_array.each do |filepath|
        apply_filepath(array, filepath, error_key)
      end
    end
end
