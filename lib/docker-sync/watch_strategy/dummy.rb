require 'thor/shell'
require 'docker-sync/execution'

module DockerSync
  module WatchStrategy
    class Dummy
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
      end

      def run
        say_status 'success', 'Watcher disabled by configuration' if @options['verbose']
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
