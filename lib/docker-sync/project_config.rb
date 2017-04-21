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

    ERROR_MISSING_SYNCS = 'no syncs defined'.freeze

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
        raise ERROR_MISSING_SYNCS unless config.key?('syncs')

        validate_syncs_config!
      end

      def validate_syncs_config!
        config['syncs'].each do |name, sync_config|
          validate_sync_config(name, sync_config)
        end
      end

      def validate_sync_config(name, sync_config)
        config_mandatory = %w[src]
        #TODO: Implement autodisovery for other strategies
        config_mandatory.push('sync_host_port') if sync_config['sync_strategy'] == 'rsync'
        config_mandatory.each do |key|
          raise ("#{name} does not have #{key} configuration value set - this is mandatory") unless sync_config.key?(key)
        end
      end

      def error_missing_given_config
        "Config could not be loaded from #{config_path} - it does not exist"
      end

  end
end
