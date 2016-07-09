require 'thor/shell'
require 'preconditions'

module Docker_Sync
  module SyncStrategy
    class Rsync
      include Thor::Shell
      include Preconditions

      @options
      @sync_name
      @watch_thread

      def initialize(sync_name, options)
        @sync_name = sync_name
        @options = options

        begin
          rsync_available
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

      # starts a rsync docker container listening on the specific port
      # this container exposes a named volume and is on one side used as the rsync-endpoint for the
      # local rsync command, on the other side the volume is mounted into the app-container to share the code / content
      def start_container
        say_status 'ok', 'Starting rsync', :white
        running = `docker ps --filter 'status=running' --filter 'name=#{@sync_name}' | grep #{@sync_name}`
        if running == '' # container is yet not running
          say_status 'ok', "#{@sync_name} container not running", :white if @options['verbose']
          exists = `docker ps --filter "status=exited" --filter "name=#{@sync_name}" | grep #{@sync_name}`
          if exists == '' # container has yet not been created
            say_status 'ok', "creating #{@sync_name} container", :white if @options['verbose']

            user_mapping = ''
            if @options.key?('sync_user')
              user_mapping = "-e OWNER=#{@options['sync_user']}"
              if @options.key?('sync_userid')
                user_mapping = "#{user_mapping} -e OWNERID=#{@options['sync_userid']}"
              end
            elsif @options.key?('sync_userid')
              raise("#{@sync_name}: You have set a sync_userid but no sync_user - you need to set both")
            end

            group_mapping = ''
            if @options.key?('sync_group')
              group_mapping = "-e GROUP=#{@options['sync_group']}"
              if @options.key?('sync_groupid')
                group_mapping = "#{group_mapping} -e GROUPID=#{@options['sync_groupid']}"
              end
            elsif @options.key?('sync_groupid')
              raise("#{@sync_name}: You have set a sync_groupid but no sync_group - you need to set both")
            end

            cmd = "docker run -p '#{@options['sync_host_port']}:873' -v #{@sync_name}:#{@options['dest']} #{user_mapping} #{group_mapping} -e VOLUME=#{@options['dest']} --name #{@sync_name} -d eugenmayer/rsync"
          else # container already created, just start / reuse it
            say_status 'ok', "starting #{@sync_name} container", :white if @options['verbose']
            cmd = "docker start #{@sync_name}"
          end
          say_status 'command', cmd, :white if @options['verbose']
          `#{cmd}` || raise('Start failed')
        else
          say_status 'ok', "#{@sync_name} container still running", :blue if @options['verbose']
        end
        say_status 'ok', "starting initial #{@sync_name} of src", :white if @options['verbose']
        # this sleep is needed since the container could be not started
        sleep 1
        sync
        say_status 'success', 'Rsync server started', :green
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
