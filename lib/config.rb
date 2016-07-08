require 'pp'
require 'Pathname'
# this has basically completely reused from Thor::runner.rb - thank you!

module DockerSyncConfig
  def find_config
    files = find_config_file
    if files.length > 0
      return files.pop
    else
      raise('No docker-sync.yml configuration found in your path ( traversing up ) Did you define it for your project?')
    end
  end
  # this has been ruthlessly stolen from Thor/runner.rb - please do not hunt me for that :)
  def find_config_file(skip_lookup = false)
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
        docker_sync_files = globs_for_config(path).map { |g| Dir[g] }.flatten
        break unless docker_sync_files.empty?
      end
    end

    files = []
    files += docker_sync_files
  end

  # Where to look for docker-sync.yml files.
  #
  def globs_for_config(path)
    path = escape_globs(path)
    ["#{path}/docker-sync.yml"]
  end

  def escape_globs(path)
    path.to_s.gsub(/[*?{}\[\]]/, '\\\\\\&')
  end
end