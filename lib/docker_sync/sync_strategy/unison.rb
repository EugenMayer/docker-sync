require 'thor/shell'
require 'preconditions'
require 'open3'

module Docker_Sync
  module SyncStrategy
    class Unison
      include Thor::Shell
      include Preconditions


      @options
      @sync_name
      @watch_thread
      UNISON_IMAGE = 'leighmcculloch/unison'
      UNISON_VERSION = '2.48.3'
      UNISON_CONTAINER_PORT = '5000'
      def initialize(sync_name, options)
        @sync_name = sync_name
        @options = options

        begin
          unison_available
        rescue Exception => e
          say_status 'error', "#{@sync_name} has been configured to sync with unison, but no unison available", :red
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
        cmd = 'unison ' + args.join(' ')

        say_status 'command', cmd, :white if @options['verbose']

        stdout, stderr, exit_status = Open3.capture3(cmd)
        if not exit_status.success?
          say_status 'error', "Error starting sync, exit code #{$?.exitstatus}", :red
          say_status 'message', stderr
        else
          say_status 'ok', "Synced #{@options['src']}", :white
          if @options['verbose']
            say_status 'output', stdout
          end
        end
      end

      def sync_options
        args = []

        unless @options['sync_excludes'].nil?
          # TODO: does unison support excludes as a command parameter? seems to be a config-value only
          say_status 'warning','Excludes are yet not implemented for unison!', :yellow
          #  args = @options['sync_excludes'].map { |pattern| "--exclude='#{pattern}'" } + args
        end
        args.push(@options['src'])
        args.push('-auto')
        args.push('-batch')
        args.push(@options['sync_args']) if @options.key?('sync_args')
        args.push("socket://#{@options['sync_host_ip']}:#{@options['sync_host_port']}/")
        args.push('-debug verbose') if @options['verbose']
        if @options.key?('sync_user') || @options.key?('sync_group') || @options.key?('sync_groupid') || @options.key?('sync_userid')
          raise('Unison does not support sync_user, sync_group, sync_groupid or sync_userid - please use rsync if you need that')
        end
        return args
      end

      def start_container
        say_status 'ok', 'Starting unison', :white
        container_name = get_container_name
        volume_name = get_volume_name

        running = `docker ps --filter 'status=running' --filter 'name=#{container_name}' | grep #{container_name}`
        if running == ''
          say_status 'ok', "#{container_name} container not running", :white if @options['verbose']
          exists = `docker ps --filter "status=exited" --filter "name=#{container_name}" | grep #{container_name}`
          if exists == ''
            say_status 'ok', "creating #{container_name} container", :white if @options['verbose']
            cmd = "docker run -p '#{@options['sync_host_port']}:#{UNISON_CONTAINER_PORT}' -v #{volume_name}:#{@options['dest']} -e UNISON_VERSION=#{UNISON_VERSION} -e UNISON_WORKING_DIR=#{@options['dest']} --name #{container_name} -d #{UNISON_IMAGE}"
          else
            say_status 'ok', "starting #{container_name} container", :white if @options['verbose']
            cmd = "docker start #{container_name}"
          end
          say_status 'command', cmd, :white if @options['verbose']
          `#{cmd}` || raise('Start failed')
        else
          say_status 'ok', "#{container_name} container still running", :blue
        end
        say_status 'ok', "starting initial #{container_name} of src", :white if @options['verbose']
        # this sleep is needed since the container could be not started
        sleep 1
        sync
        say_status 'success', 'Unison server started', :green
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
        rescue Exception => e
          say_status 'error', "Stopping failed of #{get_container_name}:", :red
          puts e.message
        end
      end
    end
  end
end
