module DockerSync
  module Dependencies
    module Unox
      LEGACY_UNOX_WARNING          = 'You installed unison-fsmonitor (unox) the old legacy way (i.e. not using brew). We need to fix that.'.freeze
      FAILED_TO_REMOVE_LEGACY_UNOX = 'Failed to remove legacy unison-fsmonitor (unox). Please delete /usr/local/bin/unison-fsmonitor manually and try again.'.freeze

      class << self
        extend Forwardable
        def_delegators :"Thor::Shell::Color.new", :say_status, :yes?
      end

      def self.available?
        return @available if defined? @available
        cmd = 'brew list unox &> /dev/null'
        @available = defined?(Bundler) ? Bundler.with_clean_env { system(cmd) } : system(cmd)
      end

      def self.ensure!
        return if available?
        cleanup_legacy if File.exist?('/usr/local/bin/unison-fsmonitor')
        PackageManager.install_package('eugenmayer/dockersync/unox')
      end

      def self.cleanup_legacy
        uninstall_cmd = 'sudo rm -f /usr/local/bin/unison-fsmonitor'
        say_status 'warning', LEGACY_UNOX_WARNING, :yellow
        raise(FAILED_TO_REMOVE_LEGACY_UNOX) unless yes?('Uninstall legacy unison-fsmonitor (unox)? (y/N)')
        say_status 'command', uninstall_cmd, :white
        system(uninstall_cmd)
      end
    end
  end
end
