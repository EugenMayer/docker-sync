require 'docker-sync/sync_manager'
require 'docker-sync/config'
require 'docker-sync/preconditions'
require 'docker-sync/update_check'
require 'docker-sync/upgrade_check'

class Sync < Thor

  class_option :config, :aliases => '-c',:default => nil, :type => :string, :desc => 'Path of the docker_sync config'
  class_option :sync_name, :aliases => '-n',:type => :string, :desc => 'If given, only this sync configuration will be references/started/synced'

  desc 'start', 'Start all sync configurations in this project'
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
    @sync_manager.join_threads
  end

  desc 'sync', 'sync - do not start a watcher'
  def sync
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
    @sync_manager.sync(options[:sync_name])
  end

  desc 'clean', 'Stop and clean up all sync endpoints'
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
    @sync_manager.clean(options[:sync_name])
    say_status 'success', 'Finished cleanup. Removed stopped, removed sync container and removed there volumes', :green
  end

  desc 'list', 'List all sync-points of the project configuration path'
  method_option :verbose, :default => false, :type => :boolean, :desc => 'Verbose output'
  def list
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

    say_status 'ok',"Found configuration at #{config_path}"
    @sync_manager = Docker_sync::SyncManager.new(:config_path => config_path)
    @sync_manager.get_sync_points.each do |name, config|
      say_status name, "On address #{config['sync_host_ip']}:#{config['sync_host_port']}",:white unless options['verbose']
      puts "\n---------------[#{name}] #{config['sync_host_ip']}:#{config['sync_host_port']} ---------------\n" if options['verbose']
      print_table(config) if options['verbose']
    end
  end
  desc 'start', 'Start all sync configurations in this project'
  def upgrade
    # do run update check in the start command only
    upgrades = UpgradeChecker.new
    upgrades.run
  end

end
