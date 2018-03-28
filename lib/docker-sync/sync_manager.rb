require 'thor/shell'
# noinspection RubyResolve
require 'docker-sync/sync_process'
# noinspection RubyResolve
require 'docker-sync/execution'

module DockerSync
  class SyncManager
    include Thor::Shell

    @sync_processes
    @configurations
    @config_path

    def initialize(options)
      @sync_processes = []

      load_configuration(options)
    end

    def global_options
      return @config_global
    end

    def get_sync_points
      return @config_syncs
    end

    def upgrade_syncs_config
      @config_syncs.each do |name, config|
        @config_syncs[name]['config_path'] = @config_path

        @config_syncs[name]['cli_mode'] = @config_global['cli_mode'] || 'auto'

        # set the global verbose setting, if the sync-endpoint does not define a own one
        unless config.key?('verbose')
          @config_syncs[name]['verbose'] = false
          if @config_global.key?('verbose')
            @config_syncs[name]['verbose'] = @config_global['verbose']
          end
        end

        # set the global max_attempt setting, if the sync-endpoint does not define a own one
        unless config.key?('max_attempt')
          if @config_global.key?('max_attempt')
            @config_syncs[name]['max_attempt'] = @config_global['max_attempt']
          end
        end

        if @config_syncs[name].key?('dest')
          puts 'Please do no longer use "dest" in your docker-sync.yml configuration - also see https://github.com/EugenMayer/docker-sync/wiki/1.2-Upgrade-Guide#dest-has-been-removed!'
          exit 1
        else
          @config_syncs[name]['dest'] = '/app_sync'
        end

        # for each strategy check if a custom image has been defined and inject that into the sync-endpoints
        # which do fit for this strategy
        %w(rsync unison native_osx native).each do |strategy|
          if @config_global.key?("#{strategy}_image")
            @config_syncs[name]['image'] = @config_global["#{strategy}_image"]
          end

          if config.key?("#{strategy}_image") && @config_syncs[name]['sync_strategy'] == strategy
            @config_syncs[name]['image'] = config["#{strategy}_image"]
          end
        end
      end
    end

    def init_sync_processes(sync_name = nil)
      return if @sync_processes.size != 0
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

    def start_container(sync_name = nil)
      init_sync_processes(sync_name)
      @sync_processes.each { |sync_process|
        sync_process.start_container
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
          if sync_process.watch_thread
            sync_process.watch_thread.join
          end
          if sync_process.watch_fork
            Process.wait(sync_process.watch_fork)
          end
        end

      rescue SystemExit, Interrupt
        say_status 'shutdown', 'Shutting down...', :blue
        @sync_processes.each do |sync_process|
          sync_process.stop
        end

      rescue StandardError => e
        puts "EXCEPTION: #{e.inspect}"
        puts "MESSAGE: #{e.message}"
      end
    end

    def create_sync(sync_name, sync_configuration)
      sync_process = DockerSync::SyncProcess.new(sync_name, sync_configuration)
      return sync_process
    end

    def stop
      init_sync_processes
      @sync_processes.each { |sync_process|
        sync_process.stop
        unless sync_process.watch_thread.nil?
          sync_process.watch_thread.kill unless sync_process.watch_thread.nil?
        end
      }
    end

    def watch_stop
      @sync_processes.each { |sync_process|
        sync_process.watch_thread.kill unless sync_process.watch_thread.nil?
      }
    end

    def watch_start
      @sync_processes.each { |sync_process|
        sync_process.watch
      }
    end

    private

      def load_configuration(options)
        config = options[:config] ||
          DockerSync::ProjectConfig.new(
            config_path: options[:config_path],
            config_string: options[:config_string]
          )

        @config_path = config.config_path
        @config_global = config['options'] || {}
        @config_syncs = config['syncs']
        upgrade_syncs_config
      end

  end
end
