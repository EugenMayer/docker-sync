require 'forwardable'

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
        # should never have been called anyway - fix the call that it should check for the OS
        raise 'Unox cannot be available for other platforms then MacOS' unless Environment.mac?

        return @available if defined? @available
        cmd = 'brew list unox 2>&1 > /dev/null'
        @available = Environment.system(cmd)
        @available
      end

      def self.ensure!
        return if available?
        raise 'Unox cannot be installed on other platforms then MacOS' unless Environment.mac?

        cleanup_non_brew_version!
        PackageManager.install_package('eugenmayer/dockersync/unox')
      end

      def self.cleanup_non_brew_version!
        return unless non_brew_version_installed?
        uninstall_cmd = 'sudo rm -f /usr/local/bin/unison-fsmonitor'
        say_status 'warning', LEGACY_UNOX_WARNING, :yellow
        raise(FAILED_TO_REMOVE_LEGACY_UNOX) unless yes?('Uninstall legacy unison-fsmonitor (unox)? (y/N)')
        say_status 'command', uninstall_cmd, :white
        Environment.system(uninstall_cmd)
      end

      def self.non_brew_version_installed?
        !available? && File.exist?('/usr/local/bin/unison-fsmonitor')
      end
    end
  end
end
