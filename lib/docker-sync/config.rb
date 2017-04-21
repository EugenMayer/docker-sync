require 'pp'
require 'pathname'
require 'yaml'
require 'dotenv'
require 'docker-sync/config_template'

# this has basically completely reused from Thor::runner.rb - thank you!
module DockerSyncConfig

  def initialize(options)
    load_dotenv
  end

  def self.load_dotenv
    env_file = ENV.fetch('DOCKER_SYNC_ENV_FILE', '.env')
    Dotenv.load(env_file)
  end

  def self.project_required_config_version
    return '2'
  end

  def self.project_ensure_configuration_version_compatibility(config)
    return false unless config.key?('version')
    return false if config['version'].to_s != project_required_config_version.to_s
    return true
  end

  def self.project_config_path
    files = project_config_find
    if files.length > 0
      path =  files.pop
    else
      raise('No docker-sync.yml configuration found in your path ( traversing up ) Did you define it for your project?')
    end

    begin
      config = YAML.load_file(path)
      raise "Version of docker-sync.yml does not match the reqiured one" unless project_ensure_configuration_version_compatibility(config)
    rescue Exception => e
      raise "You docker-sync.yml file does either not include a version: \"#{project_required_config_version}\" setting or your setting (#{config['version']}) does not match the required version (#{project_required_config_version}). (Add this if you migrated from docker-sync 0.1.x)"
    end
    return path
  end

  # this has been ruthlessly stolen from Thor/runner.rb - please do not hunt me for that :)
  def self.project_config_find(skip_lookup = false)
    # Finds docker-sync.yml by traversing from your current directory down to the root
    # directory of your system. If at any time we find a docker-sync.yml file, we stop.
    #
    #
    # ==== Example
    #
    # If we start at /Users/wycats/dev/thor ...
    #
    # 1. /Users/wycats/dev/thor
    # 2. /Users/wycats/dev
    # 3. /Users/wycats <-- we find a docker-sync.yml here, so we stop
    #
    # Suppose we start at c:\Documents and Settings\james\dev\docker-sync ...
    #
    # 1. c:\Documents and Settings\james\dev\docker-sync.yml
    # 2. c:\Documents and Settings\james\dev
    # 3. c:\Documents and Settings\james
    # 4. c:\Documents and Settings
    # 5. c:\ <-- no docker-sync.yml found!
    #
    docker_sync_files = []

    unless skip_lookup
      Pathname.pwd.ascend do |path|
        docker_sync_files = globs_for_project_config(path).map { |g| Dir[g] }.flatten
        break unless docker_sync_files.empty?
      end
    end

    files = []
    files += docker_sync_files
  end

  # Where to look for docker-sync.yml files.
  #
  def self.globs_for_project_config(path)
    path = escape_globs(path)
    ["#{path}/docker-sync.yml"]
  end

  def self.escape_globs(path)
    path.to_s.gsub(/[*?{}\[\]]/, '\\\\\\&')
  end
end
