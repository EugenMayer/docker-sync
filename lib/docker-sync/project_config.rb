require 'singleton'

module DockerSync
  class ProjectConfig
    extend Forwardable

    REQUIRED_CONFIG_VERSION = '2'.freeze

    ERROR_MISSING_CONFIG_VERSION =
      "Your docker-sync.yml file does not include a version: \"#{REQUIRED_CONFIG_VERSION}\""\
      '(Add this if you migrated from docker-sync 0.1.x)'.freeze

    ERROR_MISMATCH_CONFIG_VERSION =
      'Your docker-sync.yml file does not match the required version '\
      "(#{REQUIRED_CONFIG_VERSION}).".freeze

    attr_reader :config, :config_path
    private :config

    def_delegators :@config, :[], :to_h

    def initialize(config_path: nil, config_string: nil)
      if config_string
        @config = DockerSync::ConfigLoader.interpolate_config_string(config_string)
      else
        @config_path = config_path || DockerSync::ConfigLoader.lookup_project_config
        @config = DockerSync::ConfigLoader.load_config(@config_path)
      end

      validate_config!
    end

    private

      def validate_config!
        raise error_missing_given_config if config.nil?
        raise ERROR_MISSING_CONFIG_VERSION unless config.key?('version')
        raise ERROR_MISMATCH_CONFIG_VERSION unless config['version'].to_s == REQUIRED_CONFIG_VERSION
      end

      def error_missing_given_config
        "Config could not be loaded from #{config_path} - it does not exist"
      end

  end
end
