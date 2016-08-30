require 'thor/shell'
require 'docker-sync/preconditions'
require 'terminal-notifier'

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
        # if a custom image is set, apply it
        if @options.key?('image')
          @docker_image = @options['image']
        else
          @docker_image = 'eugenmayer/rsync'
        end

        begin
          Preconditions::rsync_available
        rescue Exception => e
          say_status 'error', "#{@sync_name} has been configured to sync with rsync, but no rsync binary available", :red
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
        args.push("#{@options['src']}/") # add a trailing slash
        args.push("rsync://#{@options['sync_host_ip']}:#{@options['sync_host_port']}/volume")
        return args
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
        say_status 'ok', 'Starting rsync', :white
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

            cmd = "docker run -p '#{@options['sync_host_port']}:873' -v #{volume_name}:#{@options['dest']} #{user_mapping} #{group_mapping} -e VOLUME=#{@options['dest']} -e TZ=${TZ-`readlink /etc/localtime | sed -e 's,/usr/share/zoneinfo/,,'`} --name #{container_name} -d #{@docker_image}"
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
        # this sleep is needed since the container could be not started
        sleep 1
        sync
        say_status 'success', 'Rsync server started', :green
      end

      def get_user_mapping
        user_mapping = ''
        if @options.key?('sync_user')
          user_mapping = "-e OWNER=#{@options['sync_user']}"
          if @options.key?('sync_userid')
            user_mapping = "#{user_mapping} -e OWNERID=#{@options['sync_userid']}"
          end
        elsif @options.key?('sync_userid')
          raise("#{get_container_name}: You have set a sync_userid but no sync_user - you need to set both")
        end
        return user_mapping
      end

      def get_group_mapping
        group_mapping = ''
        if @options.key?('sync_group')
          group_mapping = "-e GROUP=#{@options['sync_group']}"
          if @options.key?('sync_groupid')
            group_mapping = "#{group_mapping} -e GROUPID=#{@options['sync_groupid']}"
          end
        elsif @options.key?('sync_groupid')
          raise("#{get_container_name}: You have set a sync_groupid but no sync_group - you need to set both")
        end
        return group_mapping
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
        rescue Exception => e
          say_status 'error', "Stopping failed of #{get_container_name}:", :red
          puts e.message
        end
      end
    end
  end
end
