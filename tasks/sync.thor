require 'docker_sync/sync_manager'
require 'config'

class Sync < Thor
  class_option :config, :aliases => '-c',:type => :string, :desc => 'Path of the docker_sync config'
  class_option :sync_name, :aliases => '-n',:type => :string, :desc => 'If given, only this sync configuration will be references/started/synced'

  desc 'start', 'Start all sync configurations in this project'
  def start
    if options[:config]
      config_path = options[:config]
    else
      config_path = find_config
    end
    @sync_manager = Docker_Rsync::SyncManager.new(:config_path => config_path)
    @sync_manager.run(options[:sync_name])
  end

  desc 'sync_only', 'sync - do not start a watcher'
  def sync
    if options[:config]
      config_path = options[:config]
    else
      config_path = find_config
    end
    @sync_manager = Docker_Rsync::SyncManager.new(:config_path => config_path)
    @sync_manager.sync(options[:sync_name])
  end
end
