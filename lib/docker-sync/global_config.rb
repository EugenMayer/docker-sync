require 'singleton'

module DockerSync
  class GlobalConfig
    extend Forwardable
    include Singleton

    CONFIG_PATH = File.expand_path('~/.docker-sync-global.yml')
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
      @config = DockerSync::ConfigLoader.load_config(CONFIG_PATH)

      unless @config
        @config = DEFAULTS.dup
        @first_run = true
      end
    end

    def first_run?
      @first_run
    end

    def update!(updates)
      config.merge!(updates)

      File.open(CONFIG_PATH, 'w') {|f| f.write config.to_yaml }
    end
  end
end
