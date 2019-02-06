require 'thor/shell'
require 'docker-sync/execution'
require 'open3'
require 'socket'
require 'terminal-notifier'

module DockerSync
  module SyncStrategy
    class Unison
      include Thor::Shell
      include Execution

      @options
      @sync_name
      @watch_thread
      @local_server_pid
      UNISON_CONTAINER_PORT = '5000'
      def initialize(sync_name, options)
        @options = options
        @sync_name = sync_name
        # if a custom image is set, apply it
        if @options.key?('image')
          @docker_image = @options['image']
        else
          @docker_image = 'eugenmayer/unison:2.51.2.1'
        end
        begin
          Dependencies::Unison.ensure!
          Dependencies::Unox.ensure! if Environment.mac?
        rescue StandardError => e
          say_status 'error', "#{@sync_name} has been configured to sync with unison, but no unison available", :red
          say_status 'error', e.message, :red
          exit 1
        end
      end

      def run
        increase_watcher_limit if @options.key?('max_inotify_watches')
        start_container
        sync
      end

      def increase_watcher_limit
        current_max_files_per_proc = `sysctl kern.maxfilesperproc | awk '{print $2}'`
        if current_max_files_per_proc.to_f < @options['max_inotify_watches']
          cmd = 'sudo sysctl -w kern.maxfilesperproc=' + @options['max_inotify_watches'].to_s
          say_status 'command', cmd, :white
          `#{cmd}` || raise('Unable to increase maxfilesperproc')
        else
          say_status 'command', 'Current maxfilesperproc set to ' + current_max_files_per_proc.to_s, :white
        end
        current_max_files = `sysctl kern.maxfiles | awk '{print $2}'`
        if current_max_files.to_f < @options['max_inotify_watches']
          cmd = 'sudo sysctl -w kern.maxfiles=' + @options['max_inotify_watches'].to_s
          say_status 'command', cmd, :white
          `#{cmd}` || raise('Unable to increase maxfiles')
        else
          say_status 'command', 'Current maxfiles set to ' + current_max_files.to_s, :white
        end
      end

      def watch
        args = sync_options
        args.push("-repeat watch")
        cmd = ''
        cmd = cmd + 'ulimit -n ' + @options['max_inotify_watches'].to_s + ' && ' if @options.key?('max_inotify_watches')
        cmd = cmd + 'unison ' + args.join(' ')

        say_status 'command', cmd, :white if @options['verbose']
        fork_exec(cmd, "Sync #{@sync_name}", :blue)
      end

      def sync
        args = sync_options
        cmd = 'unison ' + args.join(' ')

        say_status 'command', cmd, :white if @options['verbose']

        stdout, stderr, exit_status = Open3.capture3(cmd)
        if not exit_status.success?
          say_status 'error', "Error starting sync, exit code #{$?.exitstatus}", :red
          say_status 'message', stdout
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

      def expand_ignore_strings
        expanded_ignore_strings = []

        exclude_type = 'Name'
        unless @options['sync_excludes_type'].nil?
          exclude_type = @options['sync_excludes_type']
        end

        unless @options['sync_excludes'].nil?
          expanded_ignore_strings = @options['sync_excludes'].map do |pattern|
            if exclude_type == 'none'
              # the ignore type like Name / Path are part of the pattern
              ignore_string = "#{pattern}"
            else
              ignore_string = "#{exclude_type} #{pattern}"
            end
            "-ignore='#{ignore_string}'"
          end
        end
        expanded_ignore_strings
      end

      def sync_options
        args = []
        args = expand_ignore_strings + args
        args.push("'#{@options['src']}'")
        args.push('-auto')
        args.push('-batch')
        args.push(sync_prefer)
        args.push(@options['sync_args']) if @options.key?('sync_args')
        sync_host_port = get_host_port(get_container_name, UNISON_CONTAINER_PORT)
        args.push("socket://#{@options['sync_host_ip']}:#{sync_host_port}")

        if @options.key?('sync_group') || @options.key?('sync_groupid')
          raise('Unison does not support sync_group, sync_groupid - please use rsync if you need that')
        end
        return args
      end

      # cares about conflict resolution
      def sync_prefer
        case @options.fetch('sync_prefer', 'default')
          when 'default' then "-prefer '#{@options['src']}' -copyonconflict" # thats our default, if nothing is set
          when 'src' then "-prefer '#{@options['src']}'"
          when 'dest' then "-prefer 'socket://#{@options['sync_host_ip']}:#{sync_host_port}'"
          else "-prefer '#{@options['sync_prefer']}'"
        end
      end


      def start_container
        say_status 'ok', "Starting unison for sync #{@sync_name}", :white

        container_name = get_container_name
        volume_name = get_volume_name
        env = {}
        raise 'sync_user is no longer supported, since it ise no needed, use sync_userid only please' if @options.key?('sync_user')

        env['UNISON_SRC'] = '-socket 5000'
        env['UNISON_DEST'] = '/app_sync'


        env['MONIT_ENABLE'] = 'false'
        env['MONIT_INTERVAL'] = ''
        env['MONIT_HIGH_CPU_CYCLES'] = ''

        env['UNISON_ARGS'] = ''
        ignore_strings = expand_ignore_strings
        env['UNISON_ARGS'] << ignore_strings.join(' ')
        env['UNISON_WATCH_ARGS'] = ''

        env['MAX_INOTIFY_WATCHES'] = @options['max_inotify_watches'] if @options.key?('max_inotify_watches')
        if @options['sync_userid'] == 'from_host'
          env['OWNER_UID'] = Process.uid
        else
          env['OWNER_UID'] = @options['sync_userid'] if @options.key?('sync_userid')
        end

        # start unison-image in unison socket mode mode
        env['HOSTSYNC_ENABLE']=0
        env['UNISONSOCKET_ENABLE']=1

        additional_docker_env = env.map{ |key,value| "-e #{key}=\"#{value}\"" }.join(' ')
        running = `docker ps --filter 'status=running' --filter 'name=#{container_name}' --format "{{.Names}}" | grep '^#{container_name}$'`
        if running == ''
          say_status 'ok', "#{container_name} container not running", :white if @options['verbose']
          exists = `docker ps --filter "status=exited" --filter "name=#{container_name}" --format "{{.Names}}" | grep '^#{container_name}$'`
          if exists == ''
            run_privileged = ''
            run_privileged = '--privileged' if @options.key?('max_inotify_watches') #TODO: replace by the minimum capabilities required
            tz_expression = '-e TZ=$(basename $(dirname `readlink /etc/localtime`))/$(basename `readlink /etc/localtime`)'
            say_status 'ok', 'Starting precopy', :white if @options['verbose']
            # we just run the precopy script and remove the container
            cmd = "docker run --rm -v \"#{volume_name}:#{@options['dest']}\" -e APP_VOLUME=#{@options['dest']} #{tz_expression} #{additional_docker_env} #{run_privileged} --name #{container_name} #{@docker_image} /usr/local/bin/precopy_appsync"
            say_status 'precopy', cmd, :white if @options['verbose']
            system(cmd) || raise('Precopy failed')

            say_status 'ok', "creating #{container_name} container", :white if @options['verbose']
            cmd = "docker run -p '#{@options['sync_host_ip']}::#{UNISON_CONTAINER_PORT}' -v #{volume_name}:#{@options['dest']} -e APP_VOLUME=#{@options['dest']} #{tz_expression} #{additional_docker_env} #{run_privileged} --name #{container_name} -d #{@docker_image}"
          else
            say_status 'ok', "starting #{container_name} container", :white if @options['verbose']
            cmd = "docker start #{container_name} && docker exec #{container_name} supervisorctl restart unison"
          end
        else
          say_status 'ok', "#{container_name} container still running, restarting unison in container", :blue
          cmd = "docker exec #{container_name} supervisorctl restart unison"
        end
        say_status 'command', cmd, :white if @options['verbose']
        `#{cmd}` || raise('Start failed')
        say_status 'ok', "starting initial sync of #{container_name}", :white if @options['verbose']
        # wait until container is started, then sync:
        sync_host_port = get_host_port(get_container_name, UNISON_CONTAINER_PORT)
        cmd = "unison -testserver #{@options['dest']} \"socket://#{@options['sync_host_ip']}:#{sync_host_port}\""
        say_status 'command', cmd, :white if @options['verbose']
        attempt = 0
        max_attempt = @options['max_attempt'] || 5
        loop do
          # noinspection RubyUnusedLocalVariable
          stdout, stderr, exit_status = Open3.capture3(cmd)
          break if exit_status == 0
          attempt += 1
          raise "Failed to start unison container in time, try to increase max_attempt (currently #{max_attempt}) in your configuration. See https://github.com/EugenMayer/docker-sync/wiki/2.-Configuration for more informations" if attempt > max_attempt
          sleep 1
        end
        sync
        say_status 'success', 'Unison server started', :green
      end

      # noinspection RubyUnusedLocalVariable
      def get_host_port(container_name, container_port)
        cmd = 'docker inspect --format=\'{{(index (index .NetworkSettings.Ports "5000/tcp") 0).HostPort}}\' ' + container_name
        say_status 'command', cmd, :white if @options['verbose']
        stdout, stderr, exit_status = Open3.capture3(cmd)
        unless exit_status.success?
          say_status 'command', cmd
          say_status 'error', "Error getting mapped port, exit code #{$?.exitstatus}", :red
          say_status 'message', stderr
        end
        return stdout.gsub("\n",'')
      end

      def get_container_name
        return "#{@sync_name}"
      end

      def get_volume_name
        return @sync_name
      end

      def stop_container
        `docker ps | grep #{get_container_name} && docker stop #{get_container_name} && docker wait #{get_container_name}`
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
