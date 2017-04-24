require 'pathname'

module DockerSync
  # helps us loading our config files, GlobalConfig and ProjectConfig
  module ConfigLocator
    ERROR_MISSING_PROJECT_CONFIG =
      'No docker-sync.yml configuration found in your path ( traversing up ) '\
      'Did you define it for your project?'.freeze

    class << self
      attr_accessor :global_config_path
      # @return [String] The path to the global config location
      def current_global_config_path
        path = global_config_path
        path = File.expand_path('~/.docker-sync-global.yml') if path.nil?
        path
      end

      # @return [String] the path to the project configuration found
      def lookup_project_config_path
        files = project_config_find

        raise ERROR_MISSING_PROJECT_CONFIG if files.empty?

        files.pop
      end

      private


      # this has been ruthlessly stolen from Thor/runner.rb - please do not hunt me for that :)
      # returns a list of file paths matching the docker-sync.yml file. The return the first one we find while traversing
      # the folder tree up
      # @return [Array]
      def project_config_find(skip_lookup = false)
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

        docker_sync_files
      end

      # Where to look for docker-sync.yml files.
      #
      def globs_for_project_config(path)
        path = escape_globs(path)
        ["#{path}/docker-sync.yml"]
      end

      def escape_globs(path)
        path.to_s.gsub(/[*?{}\[\]]/, '\\\\\\&')
      end
    end
  end
end
