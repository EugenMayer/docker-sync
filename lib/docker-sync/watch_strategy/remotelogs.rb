require 'thor/shell'
require 'docker-sync/execution'

module Docker_Sync
  module WatchStrategy
    class Remote_logs
      include Thor::Shell
      include Execution

      @options
      @sync_name
      @watch_fork
      @watch_thread

      def initialize(sync_name, options)
        @options = options
        @sync_name = sync_name
        @watch_fork = nil
        @watch_thread = nil
        @unison = Docker_Sync::SyncStrategy::NativeOsx.new(@sync_name, @options)
      end

      def run
        say_status 'success', "Showing unison logs from your sync container: #{@unison.get_container_name}", :green
        cmd = "docker exec #{@unison.get_container_name} tail -F /tmp/unison.log"
        wait_for_unison_log
        @watch_thread = threadexec(cmd, 'Sync Log:')
      end

      def stop
      end

      def clean
      end

      def watch
      end

      def watch_options
      end

      def watch_fork
        return @watch_fork
      end

      def watch_thread
        return @watch_thread
      end

      private

      def wait_for_unison_log
        say_status 'wait', "Waiting for unison to start", :white
        Timeout::timeout(30) do
          loop do
            return if unison_log_available?
            sleep 1
          end
        end
      rescue Timeout::Error
        puts
        say_status 'error', 'Unison failed to start within 30 seconds.', :red
        exit 70 # EX_SOFTWARE (according to `man sysexits`)
      end

      def unison_log_available?
        system("docker exec #{@unison.get_container_name} test -f /tmp/unison.log")
      end
    end
  end
end
