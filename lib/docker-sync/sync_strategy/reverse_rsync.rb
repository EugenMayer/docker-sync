require 'thor/shell'
require 'terminal-notifier'
require 'tmpdir'
require 'timeout'

module DockerSync
  module SyncStrategy
    class ReverseRsync
      include Thor::Shell

      @options
      @sync_name
      @watch_thread
      @rsyncd_conf_file
      @rsyncd_pid_file

      def initialize(sync_name, options)
        @sync_name = sync_name
        @options = options
        # if a custom image is set, apply it
        if @options.key?('image')
          @docker_image = @options['image']
        else
          @docker_image = 'zluiten/fswatch-rsync'
        end

        begin
          Dependencies::Rsync.ensure!
        rescue StandardError => e
          say_status 'error', "#{@sync_name} has been configured to reverse sync with rsync, but no rsync binary available", :red
          say_status 'error', e.message, :red
          exit 1
        end

        container_name = get_container_name

        temp = Dir.tmpdir
        @rsyncd_conf_file = "#{temp}/rsyncd-#{container_name}.conf"
        @rsyncd_pid_file = "#{temp}/rsyncd-#{container_name}.pid"
      end

      def start_rsyncd
        File.open(@rsyncd_conf_file, "w") do |file|
          file.write(<<NOW
pid file = #{@rsyncd_pid_file}
port = #{@options['sync_host_port']}
reverse lookup = no
munge symlinks = no
use chroot = no

[#{@sync_name}]
hosts deny = *
hosts allow = 127.0.0.1
read only = no
path = #{@options['src']}
NOW
          )
        end

        if File.exist?(@rsyncd_pid_file)
          stop_rsyncd
        end

        cmd = "rsync --daemon --config=\"#{@rsyncd_conf_file}\""
        say_status 'ok', "Starting rsync daemon with #{cmd}", :green

        pid = Process.spawn(cmd)
        Process.detach(pid)
      end

      def stop_rsyncd
        if File.exist?(@rsyncd_pid_file)
          begin
            pid = File.read("#{@rsyncd_pid_file}")
            Process.kill(:INT, -(Process.getpgid(pid.to_i)))
            Timeout::timeout(30) do
              loop do

                pid_status = system("ps -p #{pid.to_i} > /dev/null")

                if pid_status
                  sleep 1
                else
                  say_status 'ok', "Stopping rsync daemon for #{get_container_name}"
                  return
                end
              end
            end
          rescue Timeout::Error
            say_status 'error', "Failed to stop rsync daemon for #{get_container_name} within 30 seconds", :red
          end
        end

      end

      def run
        start_container
        sync
      end

      def sync
        # nop
      end

      def get_container_name
        return "#{@sync_name}"
      end

      def get_volume_name
        return @sync_name
      end

      # starts a reverse-rsync docker container and starts an rsync daemon on the host listening on the configured port
      # the container exposes a named volume and it syncs volume changes to the host using rsync command
      def start_container
        say_status 'ok', "Starting reverse-rsync for sync #{@sync_name}", :white

        container_name = get_container_name
        volume_name = get_volume_name

        start_rsyncd

        running = `docker ps --filter 'status=running' --filter 'name=#{container_name}' --format "{{.Names}}" | grep '^#{container_name}$'`
        if running == '' # container is yet not running
          say_status 'ok', "#{container_name} container not running", :white if @options['verbose']
          exists = `docker ps --filter "status=exited" --filter "name=#{container_name}" --format "{{.Names}}" | grep '^#{container_name}$'`
          if exists == '' # container has yet not been created
            say_status 'ok', "creating #{container_name} container", :white if @options['verbose']

            docker_env = get_docker_env

            cmd = "docker run -v #{volume_name}:#{@options['dest']} #{docker_env} --name #{container_name} -d #{@docker_image}"
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
        sleep 3
        sync
        say_status 'success', 'Reverse rsync container started', :green
      end

      def get_docker_env
        sync_excludes = []
        unless @options['sync_excludes'].nil?
          sync_excludes = @options['sync_excludes'].map {|pattern| "--exclude \"#{pattern}\""
          }
        end

        env_mapping = []
        env_mapping << "-e VOLUME=#{@options['dest']}"
        env_mapping << "-e TZ=$(basename $(dirname `readlink /etc/localtime`))/$(basename `readlink /etc/localtime`)"
        env_mapping << "-e ALLOW=#{@options['sync_host_allow']}" if @options['sync_host_allow']
        env_mapping << "-e RSYNC_MODULE=#{get_volume_name}"
        env_mapping << "-e RSYNC_HOST_PORT=#{@options['sync_host_port']}"
        env_mapping << "-e SYNC_EXCLUDE_ARGS='#{sync_excludes.join(' ')}'"
        env_mapping.join(' ')
      end

      def stop_container
        `docker ps | grep #{get_container_name} && docker stop #{get_container_name}`
        stop_rsyncd
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
