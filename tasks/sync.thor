require 'docker_sync/sync_manager'
require 'config'

class Sync < Thor
  include DockerSyncConfig
  class_option :config, :aliases => '-c',:default => nil, :type => :string, :desc => 'Path of the docker_sync config'
  class_option :sync_name, :aliases => '-n',:type => :string, :desc => 'If given, only this sync configuration will be references/started/synced'

  desc 'start', 'Start all sync configurations in this project'
  def start
    if options[:config]
      config_path = options[:config]
    else
      begin
        config_path = find_config
      rescue Exception => e
        say_status 'error', e.message, :red
        return
      end
    end
    @sync_manager = Docker_Rsync::SyncManager.new(:config_path => config_path)
    @sync_manager.run(options[:sync_name])
  end

  desc 'sync_only', 'sync - do not start a watcher'
  def sync
    if options[:config]
      config_path = options[:config]
    else
      begin
        config_path = find_config
      rescue Exception => e
        say_status 'error', e.message, :red
        return
      end
    end
    @sync_manager = Docker_Rsync::SyncManager.new(:config_path => config_path)
    @sync_manager.sync(options[:sync_name])
  end

  desc 'clean', 'Stop and clean up all sync endpoints'
  def clean
    if options[:config]
      config_path = options[:config]
    else
      begin
        config_path = find_config
      rescue Exception => e
        say_status 'error', e.message, :red
        return
      end
    end
    @sync_manager = Docker_Rsync::SyncManager.new(:config_path => config_path)
    @sync_manager.clean(options[:sync_name])
    say_status 'success', 'Finished cleanup. Removed stopped, removed sync container and removed there volumes', :green
  end

  desc 'list', 'List all sync-points of the project configuration path'
  method_option :verbose, :default => false, :type => :boolean, :desc => 'Verbose output'
  def list
    if options[:config]
      config_path = options[:config]
    else
      begin
        config_path = find_config
      rescue Exception => e
        say_status 'error', e.message, :red
        return
      end
    end

    say_status 'ok',"Found configuration at #{config_path}"
    @sync_manager = Docker_Rsync::SyncManager.new(:config_path => config_path)
    @sync_manager.get_sync_points.each do |name, config|
      say_status name, "On address #{config['sync_host_ip']}:#{config['sync_host_port']}",:white unless options['verbose']
      puts "\n---------------[#{name}] #{config['sync_host_ip']}:#{config['sync_host_port']} ---------------\n" if options['verbose']
      print_table(config) if options['verbose']
    end
  end

end
