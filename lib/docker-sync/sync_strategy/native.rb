require 'thor/shell'

module DockerSync
  module SyncStrategy
    class Native
      include Thor::Shell

      @options
      @sync_name

      def initialize(sync_name, options)
        @sync_name = sync_name
        @options = options

        begin
          Dependencies::Docker.ensure!
        rescue StandardError => e
          say_status 'error', "#{@sync_name} has been configured to sync with native docker volume, but docker is not found", :red
          say_status 'error', e.message, :red
          exit 1
        end
      end

      def run
        create_volume
      end

      def sync
        # noop
      end

      def get_volume_name
        @sync_name
      end

      def start_container
        # noop
      end

      def clean
        delete_volume
      end

      def stop
        # noop
      end

      private

      def create_volume
        run_cmd "docker volume create --opt type=none --opt device=\"#{@options['src']}\" --opt o=bind "\
          "--name #{get_volume_name}"

        say_status 'success', "Docker volume for #{get_volume_name} created", :white
      end

      def delete_volume
        run_cmd "docker volume ls -q | grep #{get_volume_name} && docker volume rm #{get_volume_name}"
      end

      def run_cmd(cmd)
        say_status 'command', cmd, :white if @options['verbose']

        `#{cmd}`
      end
    end
  end
end
