require 'mkmf'
require 'thor/shell'

Dir[
  File.join(File.dirname(__FILE__), 'dependencies', '**', '*.rb')
].each { |f| require f }

module DockerSync
  module Dependencies
    UNSUPPORTED_OPERATING_SYSTEM = 'Unsupported operating system. Are you sure you need DockerSync?'.freeze

    def self.ensure_all!(config)
      return ensure_all_for_mac!(config)   if Environment.mac?
      return ensure_all_for_linux!(config) if Environment.linux?
      raise(UNSUPPORTED_OPERATING_SYSTEM)
    end

    def self.ensure_all_for_mac!(config)
      PackageManager.ensure!
      Docker.ensure!

      if config.unison_required?
        Unison.ensure!
      end

      if config.rsync_required?
        Rsync.ensure!
        Fswatch.ensure!
      end
    end

    def self.ensure_all_for_linux!(_config)
      Docker.ensure!
    end
  end
end
