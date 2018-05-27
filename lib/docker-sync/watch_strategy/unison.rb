require 'thor/shell'
require 'docker-sync/execution'
require 'docker-sync/sync_strategy/unison'

module DockerSync
  module WatchStrategy
    class Unison
      include Execution

      @options
      @sync_name
      @watch_fork

      def initialize(sync_name, options)
        @options = options
        @sync_name = sync_name
        @watch_fork = nil
        # instantiate the sync task to easily access all common parameters between
        # unison sync and watch
        # basically unison watch is the command with the additionnal -repeat watch option
        # note: this doesn't run a sync
        @unison = DockerSync::SyncStrategy::Unison.new(@sync_name, @options)
      end

      def run
        @watch_fork = @unison.watch
      end

      def stop
        # Make sure @watch_fork is not nil otherwise a TypeError is thrown
        if @watch_fork
          Process.kill 'TERM', @watch_fork
          Process.wait @watch_fork
        end
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
        return nil
      end
    end
  end
end
