require 'thor/shell'
require 'docker-sync/preconditions'
require 'open3'
require 'socket'
require 'terminal-notifier'

module Docker_Sync
  module SyncStrategy
    class Unison_DualSide
      include Thor::Shell

      @options
      @sync_name
      @watch_thread
      @local_server_pid
      UNISON_CONTAINER_PORT = '5000'
      def initialize(sync_name, options)
        @sync_name = sync_name
        @options = options
        # if a custom image is set, apply it
        if @options.key?('image')
          @docker_image = @options['image']
        else
          @docker_image = 'eugenmayer/unison:dualside'
        end
        begin
          Preconditions::unison_available
        rescue Exception => e
          say_status 'error', "#{@sync_name} has been configured to sync with unison, but no unison available", :red
          say_status 'error', e.message, :red
          exit 1
        end
      end

      def run
        start_container
        start_local_server
        sync
      end

      def sync
        args = sync_options
        cmd = 'unison ' + args.join(' ')

        say_status 'command', cmd, :white if @options['verbose']

        stdout, stderr, exit_status = Open3.capture3(cmd)
        if not exit_status.success?
          say_status 'error', "Error starting sync, exit code #{$?.exitstatus}", :red
          say_status 'message', stderr
        else
          TerminalNotifier.notify(
            "Synced #{@options['src']}", :title => @sync_name
          ) if @options['notify_terminal']
          say_status 'ok', "Synced #{@options['src']}", :white
          if @options['verbose']
            say_status 'output', stdout
          end
        end
      end

      def sync_options
        args = []

        unless @options['sync_excludes'].nil?
          args = @options['sync_excludes'].map { |pattern| "-ignore='Path #{pattern}'" } + args
        end
        args.push(@options['src'])
        args.push('-auto')
        args.push('-batch')
        args.push('-owner') if @options['sync_userid'] == 'from_host'
        args.push('-numericids') if @options['sync_userid'] == 'from_host'
        args.push(@options['sync_args']) if @options.key?('sync_args')
        args.push("socket://#{@options['sync_host_ip']}:#{@options['sync_host_port']}/")
        args.push('-debug all') if @options['verbose']
        if @options.key?('sync_user') || @options.key?('sync_group') || @options.key?('sync_groupid')
          raise('Unison does not support sync_user, sync_group, sync_groupid - please use rsync if you need that')
        end
        if  @options.key?('sync_userid') && @options['sync_userid'] != 'from_host'
          raise('Unison does not support sync_userid with a parameter different than \'from_host\'')
        end
        return args
      end

      def start_container
        say_status 'ok', 'Starting unison', :white
        container_name = get_container_name
        volume_name = get_volume_name
        env = {}

        env['ENABLE_WATCH'] = 'true'
        # Excludes for fswatch and unison uses the same value both in the host and in the container
        env['FSWATCH_EXCLUDES'] = @options['watch_excludes'].map { |pattern| "--exclude='#{pattern}'" }.join(' ') if @options.key?('watch_excludes')
        env['UNISON_EXCLUDES'] = @options['sync_excludes'].map { |pattern| "-ignore='Path #{pattern}'" }.join(' ') if @options.key?('sync_excludes')
        # Specify the IP of the host to call the host unison server from the container
        env['HOST_IP'] = get_host_ip
        env['UNISON_HOST_PORT'] = @options['unison-dualside_host_server_port']

        if @options['sync_userid'] == 'from_host'
          env['UNISON_DIR_OWNER'] = Process.uid
        end

        additional_docker_env = env.map{ |key,value| "-e #{key}=\"#{value}\"" }.join(' ')
        running = `docker ps --filter 'status=running' --filter 'name=#{container_name}' | grep #{container_name}`
        if running == ''
          say_status 'ok', "#{container_name} container not running", :white if @options['verbose']
          exists = `docker ps --filter "status=exited" --filter "name=#{container_name}" | grep #{container_name}`
          if exists == ''
            say_status 'ok', "creating #{container_name} container", :white if @options['verbose']
            cmd = "docker run -p '#{@options['sync_host_port']}:#{UNISON_CONTAINER_PORT}' \
                              -v #{volume_name}:#{@options['dest']} \
                              -e UNISON_DIR=#{@options['dest']} \
                              #{additional_docker_env} \
                              --name #{container_name} \
                              -d #{@docker_image}"
          else
            say_status 'ok', "starting #{container_name} container", :white if @options['verbose']
            cmd = "docker start #{container_name}"
          end
          say_status 'command', cmd, :white if @options['verbose']
          `#{cmd}` || raise('Start failed')
        else
          say_status 'ok', "#{container_name} container still running", :blue
        end
        say_status 'ok', "starting initial sync of #{container_name}", :white if @options['verbose']
        # this sleep is needed since the container could be not started
        sleep 5 # TODO: replace with unison -testserver
        sync
        say_status 'success', 'Unison server started', :green
      end

      # Start an unison server on the host
      def start_local_server
        say_status 'ok', 'Starting local unison server', :white

        if not @options.key?('unison-dualside_host_server_port')
          raise('Missing unison-dualside_host_server_port option. In order to get files synced back automatically from the
          container, you must specify the port of the local unison server.')
        end
        cmd = "unison -socket #{@options['unison-dualside_host_server_port']}"
        say_status 'command', cmd, :white if @options['verbose']

        # Store the pid of the local unison server, to kill it when docker-sync stops
        @local_server_pid = Process.fork do
          # Run the local unison server in the source folder
          Dir.chdir(@options['src']){
            `#{cmd}` || raise('Start of local unison server failed')
          }
        end
      end

      # Try to guess the IP of the host to call the unison server from the container
      # Or use the value specified in the config option
      def get_host_ip
        if @options['unison-dualside_host_ip'] != 'auto' && @options.key?('unison-dualside_host_ip')
          host_ip = @options['host_ip']
        elsif @options['unison-dualside_host_ip'] == 'auto' || (not @options.key?('unison-dualside_host_ip'))
          host_ip = Socket.ip_address_list.find { |ai| ai.ipv4? && !ai.ipv4_loopback? }.ip_address
        end
        return host_ip
      end

      # Kill the local unison server
      def stop_local_server
        Process.kill "TERM", @local_server_pid
        Process.wait @local_server_pid
      end

      def get_container_name
        return "#{@sync_name}"
      end

      def get_volume_name
        return @sync_name
      end

      def stop_container
        `docker stop #{get_container_name}`
      end

      def reset_container
        stop_container
        `docker rm #{get_container_name}`
        `docker volume rm #{get_volume_name}`
      end

      def clean
        reset_container
      end

      def stop
        say_status 'ok', "Stopping sync container #{get_container_name}"
        begin
          stop_container
          stop_local_server
        rescue Exception => e
          say_status 'error', "Stopping failed of #{get_container_name}:", :red
          puts e.message
        end
      end
    end
  end
end
