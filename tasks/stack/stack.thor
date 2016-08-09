require 'docker-sync/sync_manager'
require 'docker-sync/config'
require 'docker-sync/preconditions'
require 'docker-sync/update_check'
require 'docker-sync/upgrade_check'
require 'docker/compose'
require 'docker-sync/compose'
class Stack < Thor
  class_option :config, :aliases => '-c', :default => nil, :type => :string, :desc => 'Path of the docker_sync config'
  class_option :sync_name, :aliases => '-n', :type => :string, :desc => 'If given, only this sync configuration will be references/started/synced'

  desc 'start', 'Start sync services, watcher and then your docker-compose defined stack'

  def start
    # do run update check in the start command only
    updates = UpdateChecker.new
    updates.run

    upgrades = UpgradeChecker.new
    upgrades.run

    begin
      Preconditions::check_all_preconditions
    rescue Exception => e
      say_status 'error', e.message, :red
      exit 1
    end

    if options[:config]
      config_path = options[:config]
    else
      begin
        config_path = DockerSyncConfig::project_config_path
      rescue Exception => e
        say_status 'error', e.message, :red
        return
      end
    end

    @sync_manager = Docker_sync::SyncManager.new(:config_path => config_path)
    @sync_manager.run(options[:sync_name])
    global_options = @sync_manager.global_options
    @compose_manager = ComposeManager.new(global_options)

    compose_thread = Thread.new {
      @compose_manager.run
    }

    begin
      compose_thread.join
      #@sync_manager.join_threads
      rescue SystemExit, Interrupt
        say_status 'shutdown', 'Shutting down...', :blue

        @sync_manager.stop
        @compose_manager.stop
      rescue Exception => e
        puts "EXCEPTION: #{e.inspect}"
        puts "MESSAGE: #{e.message}"
    end
  end

  desc 'clean', 'compose down your app stack, stop and clean up all sync endpoints'

  def clean
    begin
      Preconditions::check_all_preconditions
    rescue Exception => e
      say_status 'error', e.message, :red
      exit 1
    end

    if options[:config]
      config_path = options[:config]
    else
      begin
        config_path = DockerSyncConfig::project_config_path
      rescue Exception => e
        say_status 'error', e.message, :red
        return
      end
    end
    @sync_manager = Docker_sync::SyncManager.new(:config_path => config_path)
    global_options = @sync_manager.global_options
    # shutdown compose first
    @compose_manager = ComposeManager.new(global_options)
    @compose_manager.clean
    say_status 'success', 'Finished cleaning up your app stack', :green

    # now shutdown sync
    @sync_manager.clean(options[:sync_name])
    say_status 'success', 'Finished cleanup. Removed stopped, removed sync container and removed there volumes', :green
  end
end

