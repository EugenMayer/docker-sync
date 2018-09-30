require 'thor/shell'
require 'docker-sync/execution'
require 'pathname'

module DockerSync
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

          unless Dependencies::Fswatch.available?
            begin
              Dependencies::Fswatch.ensure!
            rescue StandardError => e
              say_status 'error', e.message, :red
              exit 1
            end
            puts "please restart docker sync so the installation of fswatch takes effect"
            raise(UNSUPPORTED_OPERATING_SYSTEM)
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
        @watch_thread = thread_exec(cmd, "Sync #{@sync_name}", :blue)
      end

      def watch_options
        args = []
        unless @options['watch_excludes'].nil?
          args = @options['watch_excludes'].map { |pattern| "--exclude='#{pattern}'" } + args
        end
        args.push('-orIE')
        args.push(@events_to_watch.map { |pattern| "--event #{pattern}" })
        args.push(@options['watch_args']) if @options.key?('watch_args')
        args.push("'#{@options['src']}'")
        sync_command = get_sync_cli_call
        args.push(" | xargs -I -n1 #{sync_command} -n #{@sync_name} --config='#{@options['config_path']}'")
      end

      def get_sync_cli_call
        sync_command = 'thor sync:'
        case @options['cli_mode']
          when 'docker-sync'
            say_status 'ok','Forcing cli mode docker-sync',:yellow if @options['verbose']
            sync_command = 'docker-sync '
          when 'thor'
            say_status 'ok','Forcing cli mode thor',:yellow if @options['verbose']
            sync_command = 'thor sync:'
          else # 'auto' or any other, try to guss
            say_status 'ok','Cli mode is auto, selecting .. ',:white if @options['verbose']
            exec_name = File.basename($PROGRAM_NAME)
            if exec_name != 'thor'
              sync_command = 'docker-sync '
            else
              say_status 'warning', 'Called user thor, not docker-sync* wise, assuming dev mode, using thor', :yellow
            end
            say_status 'ok',".. #{sync_command}",:white if @options['verbose']
        end

        # append the actual operation
        return "#{sync_command}sync"
      end

      def watch_fork
        return nil
      end

      def watch_thread
        return @watch_thread
      end
    end
  end
end
