require 'thor/shell'
require 'terminal-notifier'

module DockerSync
  module SyncStrategy
    class Rsync
      include Thor::Shell

      @options
      @sync_name
      @watch_thread

      def initialize(sync_name, options)
        @sync_name = sync_name
        @options = options
        # if a custom image is set, apply it
        if @options.key?('image')
          @docker_image = @options['image']
        else
          @docker_image = 'eugenmayer/rsync'
        end

        begin
          Dependencies::Rsync.ensure!
        rescue StandardError => e
          say_status 'error', "#{@sync_name} has been configured to sync with rsync, but no rsync or fswatch binary available", :red
          say_status 'error', e.message, :red
          exit 1
        end
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
          TerminalNotifier.notify(
            "Synced #{@options['src']}", :title => @sync_name
          ) if @options['notify_terminal']
          say_status 'ok', "Synced #{@options['src']}", :white
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
        # we do not need to user usermap/groupmap since we started our container the way that it also maps user/group like we defined
        # in the config - see start_container
        #args.push("--usermap='*:#{@options['sync_user']}'") if @options.key?('sync_user')
        #args.push("--groupmap='*:#{@options['sync_group']}'") if @options.key?('sync_group')
        args.push("'#{@options['src']}'")
        args.push("rsync://#{@options['sync_host_ip']}:#{@options['sync_host_port']}/volume")
        return args
      end

      # sleep until rsync --dry-run succeeds in connecting to the daemon on the configured IP and port. 
      def health_check
        health_check_cmd = "rsync --dry-run rsync://#{@options['sync_host_ip']}:#{@options['sync_host_port']}:: 2> /dev/null"

        retry_counter = 0
        
        health_check_status = `#{health_check_cmd}`
        while health_check_status == '' && retry_counter < 10 do
          say_status 'ok', "waiting for rsync daemon on rsync://#{@options['sync_host_ip']}:#{@options['sync_host_port']}", :white if @options['verbose']
          retry_counter += 1
          health_check_status = `#{health_check_cmd}`
          sleep 1
        end
      end

      def get_container_name
        return "#{@sync_name}"
      end

      def get_volume_name
        return @sync_name
      end

      # starts a rsync docker container listening on the specific port
      # this container exposes a named volume and is on one side used as the rsync-endpoint for the
      # local rsync command, on the other side the volume is mounted into the app-container to share the code / content
      def start_container
        say_status 'ok', "Starting rsync for sync #{@sync_name}", :white

        container_name = get_container_name
        volume_name = get_volume_name
        running = `docker ps --filter 'status=running' --filter 'name=#{container_name}' --format "{{.Names}}" | grep '^#{container_name}$'`
        if running == '' # container is yet not running
          say_status 'ok', "#{container_name} container not running", :white if @options['verbose']
          exists = `docker ps --filter "status=exited" --filter "name=#{container_name}" --format "{{.Names}}" | grep '^#{container_name}$'`
          if exists == '' # container has yet not been created
            say_status 'ok', "creating #{container_name} container", :white if @options['verbose']

            user_mapping = get_user_mapping
            group_mapping = get_group_mapping
            docker_env = get_docker_env

            cmd = "docker run -p '#{@options['sync_host_port']}:873' -v #{volume_name}:#{@options['dest']} #{user_mapping} #{group_mapping} #{docker_env} --name #{container_name} -d #{@docker_image}"
          else # container already created, just start / reuse it
            say_status 'ok', "starting #{container_name} container", :white if @options['verbose']
            cmd = "docker start #{container_name}"
          end
          say_status 'command', cmd, :white if @options['verbose']
          `#{cmd}` || raise('Start failed')
        else
          say_status 'ok', "#{container_name} container still running", :blue if @options['verbose']
        end
        say_status 'ok', "#{container_name}: starting initial sync of #{@options['src']}", :white if @options['verbose']

        health_check
        sync
        say_status 'success', 'Rsync server started', :green
      end

      def get_user_mapping
        user_mapping = ''
        if @options.key?('sync_userid')
          user_mapping = "#{user_mapping} -e OWNER_UID=#{@options['sync_userid']}"
        end
        return user_mapping
      end

      def get_group_mapping
        group_mapping = ''
        if @options.key?('sync_groupid')
          raise 'for now, rsync does no longer support groupid, but for nearly all cases sync_userid should be enough'
          #group_mapping = "#{group_mapping} -e GROUP_ID=#{@options['sync_groupid']}"
        end
        return group_mapping
      end

      def get_docker_env
        env_mapping = []
        env_mapping << "-e VOLUME=#{@options['dest']}"
        env_mapping << "-e TZ=$(basename $(dirname `readlink /etc/localtime`))/$(basename `readlink /etc/localtime`)"
        env_mapping << "-e ALLOW=#{@options['sync_host_allow']}" if @options['sync_host_allow']
        env_mapping.join(' ')
      end

      def stop_container
        `docker ps | grep #{get_container_name} && docker stop #{get_container_name}`
      end

      def reset_container
        stop_container
        `docker ps -a | grep #{get_container_name} && docker rm #{get_container_name}`
        `docker volume ls -q | grep #{get_volume_name} && docker volume rm #{get_volume_name}`
      end

      def clean
        reset_container
      end

      def stop
        say_status 'ok', "Stopping sync container #{get_container_name}"
        begin
          stop_container
        rescue StandardError => e
          say_status 'error', "Stopping failed of #{get_container_name}:", :red
          puts e.message
        end
      end
    end
  end
end
