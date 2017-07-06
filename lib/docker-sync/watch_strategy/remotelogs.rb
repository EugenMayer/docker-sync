require 'thor/shell'
require 'docker-sync/execution'

module DockerSync
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
        @unison = DockerSync::SyncStrategy::NativeOsx.new(@sync_name, @options)
      end

      def run
        say_status 'success', "Showing unison logs from your sync container: #{@unison.get_container_name}", :green
        cmd = "docker exec #{@unison.get_container_name} tail -F /tmp/unison.log"
        @watch_thread = thread_exec(cmd, 'Sync Log:')
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
    end
  end
end
