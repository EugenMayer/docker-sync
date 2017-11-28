require 'singleton'
require 'docker-sync/config/config_locator'
require 'docker-sync/config/config_serializer'
require 'forwardable'
require 'docker-sync/environment'

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
        if config_path.nil? || config_path.empty?
          config_path = DockerSync::ConfigLocator.lookup_project_config_path
        end

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
      # noinspection RubyUnusedLocalVariable
      config['syncs'].any? { |name, sync_config|
        sync_config['sync_strategy'] == 'unison' || sync_config['watch_strategy'] == 'unison'
      }
    end

    def rsync_required?
      # noinspection RubyUnusedLocalVariable
      config['syncs'].any? { |name, sync_config|
        sync_config['sync_strategy'] == 'rsync'
      }
    end

    def fswatch_required?
      # noinspection RubyUnusedLocalVariable
      config['syncs'].any? { |name, sync_config|
        sync_config['watch_strategy'] == 'fswatch'
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
        normalize_options_config!

        config['syncs'].each do |name, sync_config|
          config['syncs'][name] = normalize_sync_config(sync_config)
        end
      end

      def normalize_options_config!
        config['options'] = {
          'project_root' => 'pwd',
        }.merge(config['options'] || {})
      end

      def normalize_sync_config(sync_config)
        {
          'sync_strategy' => sync_strategy_for(sync_config),
          'watch_strategy' => watch_strategy_for(sync_config)
        }.merge(sync_config).merge(
          'src' => expand_path(sync_config['src']),
        )
      end

      def sync_strategy_for(sync_config)
        sync_strategy = sync_config['sync_strategy']

        if %w(rsync unison native native_osx).include?(sync_strategy)
          sync_strategy
        else
          default_sync_strategy
        end
      end

      def watch_strategy_for(sync_config)
        watch_strategy = sync_config['watch_strategy']
        watch_strategy = 'dummy' if watch_strategy == 'disable'

        if %w(fswatch unison dummy).include?(watch_strategy)
          watch_strategy
        else
          default_watch_strategy(sync_config)
        end
      end

      def default_sync_strategy
        return 'native'     if Environment.linux?
        return 'native_osx' if Environment.mac? && Dependencies::Docker::Driver.docker_for_mac?
        return 'unison'     if Environment.mac?
      end

      def default_watch_strategy(sync_config)
        case sync_strategy_for(sync_config)
        when 'rsync' then 'fswatch'
        when 'unison' then 'unison'
        when 'native' then 'dummy'
        when 'native_osx' then 'remotelogs'
        else raise "you shouldn't be here"
        end
      end

      def expand_path(path)
        Dir.chdir(project_root) {
          # [nbr] convert the sync src from relative to absolute path
          # preserve '/' as it may be significant to the sync cmd
          absolute_path = File.expand_path(path)
          absolute_path << '/' if path.end_with?('/')
          absolute_path
        }
      end

      def project_root
        if use_config_path_for_project_root?
          File.dirname(@config_path)
        else
          Dir.pwd
        end
      end

      def use_config_path_for_project_root?
        config['options']['project_root'] == 'config_path' && !(@config_path.nil? || @config_path.empty?)
      end
  end
end
