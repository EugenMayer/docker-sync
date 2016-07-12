require 'thor/shell'
# noinspection RubyResolve
require 'docker-sync/sync_process'
# noinspection RubyResolve
require 'docker-sync/execution'
require 'yaml'

module Docker_Rsync
  class SyncManager
    include Thor::Shell

    @sync_processes
    @configurations
    @config_path

    def initialize(options)
      @sync_processes = []
      @config_syncs = []
      @config_options = []
      @config_syncs = []
      @config_path = options[:config_path]
      load_configuration
    end

    def load_configuration
      unless File.exist?(@config_path)
        raise "Config could not be loaded from #{@config_path} - it does not exist"
      end

      config = YAML.load_file(@config_path)
      validate_config(config)
      @config_options = config['options'] || {}
      @config_syncs = config['syncs']
      upgrade_syncs_config
    end

    def get_sync_points
      return @config_syncs
    end

    def upgrade_syncs_config
      @config_syncs.each do |name, config|
        @config_syncs[name]['config_path'] = @config_path
        # expand the sync source to remove ~ and similar expressions in the path
        @config_syncs[name]['src'] = File.expand_path(@config_syncs[name]['src'])

        # set the global verbose setting, if the sync-endpoint does not define a own one
        unless config.key?('verbose')
          @config_syncs[name]['verbose'] = false
          if @config_options.key?('verbose')
            @config_syncs[name]['verbose'] = @config_options['verbose']
          end
        end

        # for each strategy check if a custom image has been defined and inject that into the sync-endpoints
        # which do fit for this strategy
        %w(rsync unison).each do |strategy|
          if config.key?("#{strategy}_image") && @config_syncs[name]['sync_strategy'] == strategy
            @config_syncs[name]['image'] = config["#{strategy}_image"]
          end
        end
      end
    end

    def validate_config(config)
      unless config.key?('syncs')
        raise ('no syncs defined')
      end

      config['syncs'].each do |name, sync_config|
        validate_sync_config(name, sync_config)
      end

      return true
    end

    def validate_sync_config(name, sync_config)
      %w[src dest sync_host_port].each do |key|
        raise ("#{name} does not have #{key} condiguration value set - this is mandatory") unless sync_config.key?(key)
      end
    end

    def init_sync_processes(sync_name = nil)
      if sync_name.nil?
        @config_syncs.each { |name, sync_configuration|
          @sync_processes.push(create_sync(name, sync_configuration))
        }
      else
        unless @config_syncs.key?(sync_name)
          raise("Could not find sync configuration with name #{sync_name}")
        end
        @sync_processes.push(create_sync(sync_name, @config_syncs[sync_name]))
      end
    end


    def clean(sync_name = nil)
      init_sync_processes(sync_name)
      @sync_processes.each { |sync_process|
        sync_process.clean
      }
    end

    def sync(sync_name = nil)
      init_sync_processes(sync_name)
      @sync_processes.each { |sync_process|
        sync_process.sync
      }
    end

    def run(sync_name = nil)
      init_sync_processes(sync_name)

      @sync_processes.each { |sync_process|
        sync_process.run
      }
    end

    def join_threads
      begin
        @sync_processes.each do |sync_process|
          sync_process.watch_thread.join
        end

      rescue SystemExit, Interrupt
        say_status 'shutdown', 'Shutting down...', :blue
        @sync_processes.each do |sync_process|
          sync_process.stop
        end

      rescue Exception => e
        puts "EXCEPTION: #{e.inspect}"
        puts "MESSAGE: #{e.message}"
      end
    end

    def create_sync(sync_name, sync_configuration)
      sync_process = Docker_Sync::SyncProcess.new(sync_name, sync_configuration)
      return sync_process
    end

    def stop
      @sync_processes.each { |sync_process|
        sync_process.stop
        unless sync_process.watch_thread.nil?
          sync_process.watch_thread.kill
        end
      }
    end
  end
end
