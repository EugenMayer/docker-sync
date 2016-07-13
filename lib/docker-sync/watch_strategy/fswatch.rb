require 'thor/shell'
require 'docker-sync/execution'
require 'docker-sync/preconditions'

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
        @events_to_watch = %w(AttributeModified Created Link MovedFrom MovedTo Renamed Removed Updated)

        begin
          Preconditions::fswatch_available
        rescue Exception => e
          say_status 'error', e.message, :red
          exit 1
        end
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
        say_status 'success', "Starting to watch #{@options['src']} - Press CTRL-C to stop", :green
        cmd = 'fswatch ' + args.join(' ')
        say_status 'command', cmd, :white if @options['verbose']

        # run a thread here, since it is blocking
        @watch_thread = threadexec(cmd, "Sync #{@sync_name}", :blue)
      end

      def watch_options
        args = []
        unless @options['watch_excludes'].nil?
          args = @options['watch_excludes'].map { |pattern| "--exclude='#{pattern}'" } + args
        end
        args.push('-orIE')
        args.push(@events_to_watch.map { |pattern| "--event #{pattern}" })
        args.push(@options['watch_args']) if @options.key?('watch_args')
        args.push(@options['src'])

        sync_command = 'thor sync:sync'
        begin
          Preconditions::docker_sync_available
          sync_command = 'docker-sync sync'
        rescue Exception => e
          say_status 'warning', 'docker-sync not available, assuming dev mode, using thor', :yellow
          puts e.message
          sync_command = 'thor sync:sync'
        end
        args.push(" | xargs -I -n1 #{sync_command} -n #{@sync_name} --config='#{@options['config_path']}'")
      end

      def watch_thread
        return @watch_thread
      end
    end
  end
end
