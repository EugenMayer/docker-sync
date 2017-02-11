require 'pp'
require 'pathname'
require 'yaml'
require 'dotenv'
# this has basically completely reused from Thor::runner.rb - thank you!
module DockerSyncConfig

  def initialize(options)
    Dotenv.load
  end

  def self.global_config_location
    return File.expand_path('~/.docker-sync-global.yml')
  end

  def self.is_first_run
    global_config_path = global_config_location
    return !File.exist?(global_config_path)
  end

  def self.global_config
    global_config_path = global_config_location
    date = DateTime.new(2001, 1, 1) #paste
    # noinspection RubyStringKeysInHashInspection
    defaults = {'update_check'=>true, 'update_last_check' => date.iso8601(9), 'update_enforce' => true}
    if File.exist?(global_config_path)

      env_hash = {}
      ENV.each {|k,v| env_hash[k.to_sym] = v }
      config_string = File.read(global_config_path)
      config_string.gsub!('${', '%{')
      config_string = config_string % env_hash
      config = YAML.load(config_string)

      config = defaults.merge(config)
      return config
    else
      return defaults
    end
  end

  def self.global_config_save(config)
    global_config_path = global_config_location
    File.open(global_config_path, 'w') {|f| f.write config.to_yaml }
  end

  def self.project_config_path
    files = project_config_find
    if files.length > 0
      return files.pop
    else
      raise('No docker-sync.yml configuration found in your path ( traversing up ) Did you define it for your project?')
    end
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