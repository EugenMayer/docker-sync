require 'singleton'
require 'forwardable'
require 'date'

require 'docker-sync/config/config_locator'
require 'docker-sync/config/config_serializer'

module DockerSync
  class GlobalConfig
    extend Forwardable
    include Singleton

    # noinspection RubyStringKeysInHashInspection
    DEFAULTS = {
      'update_check' => true,
      'update_last_check' => DateTime.new(2001, 1, 1).iso8601(9),
      'update_enforce' => true,
      'upgrade_status' => '',
    }.freeze

    attr_reader :config
    private :config

    def_delegators :@config, :[], :to_h

    def self.load; instance end

    def initialize
      load_global_config
    end

    def load_global_config
      @config_path = DockerSync::ConfigLocator.current_global_config_path
      if File.exist?(@config_path)
        @config = DockerSync::ConfigSerializer.default_deserializer_file(@config_path)
      end

      unless @config
        @config = DEFAULTS.dup
        @first_run = true
      end
    end

    def first_run?
      @first_run
    end

    # @param [Object] updates
    # Updates and saves the configuration back to the file
    def update!(updates)
      @config.merge!(updates)

      File.open(@config_path, 'w') {|f| f.write @config.to_yaml }
    end
  end
end
