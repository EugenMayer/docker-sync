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
        if (find_executable0 'docker').nil?
          raise('Could not find docker binary in path. Please install it, e.g. using "brew install docker" or install docker-for-mac')
        end
      end

      def docker_running
        `docker ps`
        if $?.exitstatus > 0
          raise('No docker daemon seems to be running. Did you start your docker-for-mac / docker-machine?')
        end
      end

      def rsync_available
        if should_run_precondition?
          if (find_executable0 'rsync').nil?
            raise('Could not find rsync binary in path. Please install it, e.g. using "brew install rsync"')
          end
        end
      end

      def unison_available
        if should_run_precondition?
          if (find_executable0 'unison').nil?
            cmd1 = 'brew install unison'

            Thor::Shell::Basic.new.say_status 'warning', 'Could not find unison binary in $PATH. Trying to install now', :red
            Thor::Shell::Basic.new.say_status 'command', cmd1, :white
            if Thor::Shell::Basic.new.yes?('I will install unison using brew for you? (y/N)')
              system cmd1
            else
              raise('Please install it yourself using: brew install unison')
            end
          end

          unox_available
        end
      end

      def fswatch_available
        if should_run_precondition?
          if (find_executable0 'fswatch').nil?
            cmd1 = 'brew install fswatch'

            Thor::Shell::Basic.new.say_status 'warning', 'No fswatch available. Install it by "brew install fswatch Trying to install now', :red
            if Thor::Shell::Basic.new.yes?('I will install fswatch using brew for you? (y/N)')
              system cmd1
            else
              raise('Please install it yourself using: brew install fswatch')
            end
          end
        end

      end

      def is_driver_docker_for_mac?
        `docker info | grep 'Docker Root Dir: /var/lib/docker' && docker info | grep 'Operating System: Alpine Linux'`
        $?.success?
      end

      def is_driver_docker_toolbox?
        return false unless find_executable0('docker-machine')
        `docker info | grep 'Operating System: Boot2Docker'`
        $?.success?
      end

      private

      def should_run_precondition?(silent = false)
        unless has_brew?
          Thor::Shell::Basic.new.say_status 'info', 'Not running any precondition checks since you have no brew and that is unsupported. Is all up to you know.', :white unless silent
          return false
        end
        return true
      end

      def has_brew?
        return find_executable0 'brew'
      end


      def unox_available
        if should_run_precondition?
          if defined? Bundler
            Bundler.with_clean_env { `brew list unox` } 
          else
            `brew list unox`
          end
          
          unless $?.success?
            # unox installed, but not using brew, we do not allow that anymore
            if File.exist?('/usr/local/bin/unison-fsmonitor')
              Thor::Shell::Basic.new.say_status 'error', 'You installed unison-fsmonitor (unox) not using brew-method - the old legacy way. We need to fix that.', :red

              uninstall_cmd='sudo rm /usr/local/bin/unison-fsmonitor'
              Thor::Shell::Basic.new.say_status 'command', uninstall_cmd, :white
              if Thor::Shell::Basic.new.yes?('Should i uninstall the legacy /usr/local/bin/unison-fsmonitor for you ? (y/N)')
                system uninstall_cmd
              else
                Thor::Shell::Basic.new.say_status 'error', 'Uninstall /usr/local/bin/unison-fsmonitor manually please', :white
                exit 1
              end
            end

            cmd1 = 'brew tap eugenmayer/dockersync && brew install eugenmayer/dockersync/unox'
            Thor::Shell::Basic.new.say_status 'warning', 'Could not find unison-fsmonitor (unox) binary in $PATH. Trying to install now', :red
            Thor::Shell::Basic.new.say_status 'command', cmd1, :white
            if Thor::Shell::Basic.new.yes?('I will install unox through brew for you? (y/N)')
              system cmd1
            else
              raise("Please install it yourself using: #{cmd1}")
            end
          end
        end
      end
    end
  end
end
