require 'thor/shell'
require 'docker-sync/preconditions/strategy'
require 'docker-sync/execution'
require 'docker-sync/update_check'
require 'open3'
require 'socket'
require 'terminal-notifier'

module DockerSync
  module SyncStrategy
    class NativeOsx
      include Thor::Shell
      include Execution

      @options
      @sync_name
      @watch_thread
      @local_server_pid

      def initialize(sync_name, options)
        @options = options
        @sync_name = sync_name
        # if a custom image is set, apply it
        if @options.key?('image')
          @docker_image = @options['image']
        else
          @docker_image = 'eugenmayer/unison:hostsync_0.2'
        end

        # TODO: remove this when we have a more stable image, but for now, we need this
        uc = UpdateChecker.new
        uc.check_unison_hostsync_image(true)

        begin
          DockerSync::Preconditions::Strategy.instance.docker_available
        rescue Exception => e
          say_status 'error', "#{@sync_name} has been configured to sync with native docker volume, but docker is not found", :red
          say_status 'error', e.message, :red
          exit 1
        end
      end

      def start_container
        say_status 'ok', "Starting native_osx for sync #{@sync_name}", :white
        container_name = get_container_name
        host_sync_src = @options['src']
        volume_app_sync_name = @sync_name
        env = {}
        raise 'sync_user is no longer supported, since it ise no needed, use sync_userid only please', :yellow if @options.key?('sync_user')

        ignore_strings = expand_ignore_strings
        env['UNISON_EXCLUDES'] = ignore_strings.join(' ')
        env['UNISON_ARGS'] = @options['sync_args']
        env['UNISON_SYNC_PREFER'] = sync_prefer
        env['MAX_INOTIFY_WATCHES'] = @options['max_inotify_watches'] if @options.key?('max_inotify_watches')
        if @options['sync_userid'] == 'from_host'
          env['OWNER_UID'] = Process.uid
        else
          env['OWNER_UID'] = @options['sync_userid'] if @options.key?('sync_userid')
        end

        host_disk_mount_mode = '' # see https://github.com/moby/moby/pull/31047
        host_disk_mount_mode = ":#{@options['host_disk_mount_mode']}" if @options.key?('host_disk_mount_mode')

        additional_docker_env = env.map{ |key,value| "-e #{key}=\"#{value}\"" }.join(' ')
        running = `docker ps --filter 'status=running' --filter 'name=#{container_name}' --format "{{.Names}}" | grep '^#{container_name}$'`
        if running == ''
          say_status 'ok', "#{container_name} container not running", :white if @options['verbose']
          exists = `docker ps --filter "status=exited" --filter "name=#{container_name}" --format "{{.Names}}" | grep '^#{container_name}$'`
          if exists == ''
            say_status 'ok', "creating #{container_name} container", :white if @options['verbose']
            run_privileged = ''
            run_privileged = '--privileged' if @options.key?('max_inotify_watches') #TODO: replace by the minimum capabilities required
            say_status 'ok', 'Starting precopy', :white if @options['verbose']
            # we just run the precopy script and remove the container
            cmd = "docker run --rm -v #{volume_app_sync_name}:/app_sync -v #{host_sync_src}:/host_sync#{host_disk_mount_mode} -e HOST_VOLUME=/host_sync -e APP_VOLUME=/app_sync -e TZ=${TZ-`readlink /etc/localtime | sed -e 's,/usr/share/zoneinfo/,,'`} #{additional_docker_env} #{run_privileged} --name #{container_name} #{@docker_image} /usr/local/bin/precopy_appsync"
            `#{cmd}` || raise('Precopy failed')
            say_status 'ok', 'Starting container', :white if @options['verbose']
            # this will be run below and start unison, since we did not manipulate CMD
            cmd = "docker run -d -v #{volume_app_sync_name}:/app_sync -v #{host_sync_src}:/host_sync -e HOST_VOLUME=/host_sync -e APP_VOLUME=/app_sync -e TZ=${TZ-`readlink /etc/localtime | sed -e 's,/usr/share/zoneinfo/,,'`} #{additional_docker_env} #{run_privileged} --name #{container_name} #{@docker_image}"
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
        say_status 'success', 'Sync container started', :green
      end

      def run
        start_container
        sync
      end

      def watch
        # nop
      end

      def sync
        # nop
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

      def get_container_name
        @sync_name.to_s
      end

      private

      def reset_container
        stop_container
        `docker ps -a | grep #{get_container_name} && docker rm #{get_container_name}`
        `docker volume ls -q | grep #{get_volume_name} && docker volume rm #{get_volume_name}`
      end


      def get_volume_name
        return @sync_name
      end

      def stop_container
        `docker ps | grep #{get_container_name} && docker stop #{get_container_name} && docker wait #{get_container_name}`
      end


      # cares about conflict resolution
      def sync_prefer
        case @options.fetch('sync_prefer', 'default')
          when 'default' then
            '-prefer /host_sync' # thats our default, if nothing is set
          when 'src' then
            '-prefer /host_sync'
          when 'dest' then
            '-prefer /app_sync'
          when 'newer' then
            '-prefer newer'
          else
            raise 'sync_pref can only be: src or dest, no path - path is no longer needed it abstracted'
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
    end
  end
end
