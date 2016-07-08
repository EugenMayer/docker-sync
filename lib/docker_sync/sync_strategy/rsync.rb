require 'thor/shell'

module Docker_Sync
  module SyncStrategy
    class Rsync
      include Thor::Shell
      @options
      @sync_name
      @watch_thread

      def initialize(sync_name, options)
        @sync_name = sync_name
        @options = options
      end

      def run
        start_container
        sync
      end

      def sync
        args = sync_options
        cmd = 'rsync ' + args.join(' ')

        say_status 'command', cmd, :white if @options['verbose']

        out = `#{cmd}`
        if $?.exitstatus > 0
          say_status 'error', "Error starting sync, exit code #{$?.exitstatus}", :red
          say_status 'message', out
        else
          say_status 'success', "Synced #{@options['src']}", :green
          if @options['verbose']
            say_status 'output', out
          end
        end
      end

      def sync_options
        args = []
        unless @options['sync_excludes'].nil?
          args = @options['sync_excludes'].map { |pattern| "--exclude='#{pattern}'" } + args
        end
        args.push('-ap')
        args.push(@options['sync_args']) if @options.key?('sync_args')
        args.push("#{@options['src']}/") # add a trailing slash
        args.push("rsync://#{@options['sync_host_ip']}:#{@options['sync_host_port']}/volume")
      end


      def start_container
        say_status 'ok', 'Starting rsync', :white
        running = `docker ps --filter 'status=running' --filter 'name=#{@sync_name}' | grep #{@sync_name}`
        if running == ''
          say_status 'ok', "#{@sync_name} container not running", :white
          exists = `docker ps --filter "status=exited" --filter "name=filesync_dw" | grep filesync_dw`
          if exists == ''
            say_status 'ok', "creating #{@sync_name} container", :white
            cmd = "docker run -p '#{@options['sync_host_port']}:873' -v #{@sync_name}:#{@options['dest']} -e VOLUME=#{@options['dest']} --name #{@sync_name} -d eugenmayer/rsync"
          else
            say_status 'success', "starting #{@sync_name} container", :green
            cmd = "docker start #{@sync_name}"
          end
          say_status 'command', cmd, :white
          `#{cmd}` || raise('Start failed')
        else
          say_status 'ok', "#{@sync_name} container still running", :blue
        end
        say_status 'success', "starting initial #{@sync_name} of src", :green
        # this sleep is needed since the container could be not started
        sleep 1
        sync
      end

      def stop_container
        `docker stop #{@sync_name}`
      end

      def reset_container
        stop_container
        `docker rm #{@sync_name}`
        `docker volume rm #{@sync_name}`
      end

      def clean
        reset_container
      end

      def stop
        say_status 'ok', "Stopping sync container #{@sync_name}"
        begin
          stop_container
        rescue Exception => e
          say_status 'error', "Stopping failed of #{@sync_name}:", :red
          puts e.message
        end
      end
    end
  end
end
