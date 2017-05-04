require 'mkmf'
module DockerSync
  module Preconditions
    class Osx
      def check_all_preconditions(config)
        return unless should_run_precondition?

        docker_available
        docker_running

        if config.unison_required?
          unison_available
        end

        if config.rsync_required?
          rsync_available
          fswatch_available
        end
      end

      def docker_available
        raise('Could not find docker binary in path. Please install it, e.g. using "brew install docker" or install docker-for-mac') unless find_executable0('docker')
      end

      def docker_running
        raise('No docker daemon seems to be running. Did you start your docker-for-mac / docker-machine?') unless system('docker ps')
      end

      def rsync_available
        return unless should_run_precondition?
        return unless find_executable0('rsync')
        install_binary('rsync')
      end

      def unison_available
        return unless should_run_precondition?
        return unless find_executable0('unison')
        install_binary('unison')
        unox_available
      end

      def fswatch_available
        return unless should_run_precondition?
        return unless find_executable0('fswatch')
        install_binary('fswatch')
      end

      def is_driver_docker_for_mac?
        system('docker info | grep "Docker Root Dir: /var/lib/docker" && docker info | grep "Operating System: Alpine Linux"')
      end

      def is_driver_docker_toolbox?
        return false unless find_executable0('docker-machine')
        system('docker info | grep "Operating System: Boot2Docker"')
      end

      private

      def should_run_precondition?(silent = false)
        return true if has_brew?
        Thor::Shell::Basic.new.say_status 'info', 'Not running any precondition checks since you have no brew and that is unsupported. It\'s all up to you now.', :white unless silent
        false
      end

      def has_brew?
        find_executable0('brew')
      end

      def unox_available
        return unless should_run_precondition?
        return unless system('brew list unox')
        cleanup_legacy_unox if File.exist?('/usr/local/bin/unison-fsmonitor')
        install_binary('unison-fsmonitor', 'brew tap eugenmayer/dockersync && brew install eugenmayer/dockersync/unox')
      end

      def cleanup_legacy_unox
        uninstall_cmd = 'sudo rm /usr/local/bin/unison-fsmonitor'
        Thor::Shell::Basic.new.say_status 'error', 'You installed unison-fsmonitor (unox) the old legacy way (i.e. not using brew). We need to fix that.', :red
        Thor::Shell::Basic.new.say_status 'command', uninstall_cmd, :white
        raise('Please delete /usr/local/bin/unison-fsmonitor manually.') unless Thor::Shell::Basic.new.yes?('Should I uninstall the legacy unison-fsmonitor (unox) for you ? (y/N)')
        system uninstall_cmd
      end

      def install_binary(binary, install_cmd = "brew install #{binary}")
        Thor::Shell::Basic.new.say_status 'warning', "Could not find `#{binary}` in $PATH. Trying to install it now", :red
        Thor::Shell::Basic.new.say_status 'command', install_cmd, :white
        raise("Failed to install #{binary}. Please try it yourself using: #{install_cmd}") unless Thor::Shell::Basic.new.yes?('I will install unox through brew for you? (y/N)')
        system install_cmd
      end
    end
  end
end
