require 'singleton'
require 'docker-sync/config/config_locator'
require 'docker-sync/config/config_serializer'
require 'forwardable'

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
      if config_string.nil?
        config_path = DockerSync::ConfigLocator.lookup_project_config_path
        load_project_config(config_path)
      else
        @config = DockerSync::ConfigSerializer.default_deserializer_string(config_string)
        @config_path = nil
      end

      validate_config!
      normalize_config!
    end

    def load_project_config(config_path = nil)
      @config_path = config_path
      return unless File.exist?(@config_path)
      @config = DockerSync::ConfigSerializer.default_deserializer_file(@config_path)
    end

    def unison_required?
      config['syncs'].any? { |name, sync_config|
        sync_config['sync_strategy'] == 'unison' || sync_config['watch_strategy'] == 'unison'
      }
    end

    def rsync_required?
      config['syncs'].any? { |name, sync_config|
        sync_config['sync_strategy'] == 'rsync'
      }
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

      def normalize_config!
        config['syncs'].each do |name, sync_config|
          config['syncs'][name] = normalize_sync_config(sync_config)
        end
      end

      def normalize_sync_config(sync_config)
        {
          'sync_strategy' => sync_strategy_for(sync_config),
          'watch_strategy' => watch_strategy_for(sync_config)
        }.merge(sync_config)
      end

      def sync_strategy_for(sync_config)
        case sync_config['sync_strategy']
        when 'rsync' then 'rsync'
        else 'unison'
        end
      end

      def watch_strategy_for(sync_config)
        if sync_config.key?('watch_strategy')
          case sync_config['watch_strategy']
          when 'fswatch' then 'fswatch'
          when 'disable','dummy' then 'dummy'
          else 'unison'
          end
        elsif sync_config['sync_strategy'] == 'rsync'
          'fswatch'
        else
          'unison'
        end
      end

  end
end
