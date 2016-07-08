require 'thor/shell'
require 'execution'
module Docker_Sync
  module WatchStrategy
    class Fswatch
      include Thor::Shell
      include Execution
      @options
      @sync_name
      @watch_thread

      def initialize(sync_name, options)
        @sync_name = sync_name
        @options = options
      end

      def run
        watch
      end

      def stop
      end

      def clean
      end

      def watch
        args = watch_options
        say_status 'ok', "Starting to watch #{@options['src']} - Press CTRL-C to stop", :green
        cmd = 'fswatch ' + args.join(' ')
        say_status 'command', cmd, :white if @options['verbose']

        @watch_thread = threadexec(cmd, "Sync #{@sync_name}", :blue)
      end

      def watch_options
        args = []
        unless @options['watch_excludes'].nil?
          args = @options['watch_excludes'].map { |pattern| "--exclude='#{pattern}'" } + args
        end
        args.push('-orIE')
        args.push(@options['watch_args']) if @options.key?('watch_args')
        args.push(@options['src'])
        args.push(" | xargs -I -n1 thor sync:sync -n #{@sync_name} --config='#{@options['config_path']}'")
      end

      def watch_thread
        return @watch_thread
      end
    end
  end
end
