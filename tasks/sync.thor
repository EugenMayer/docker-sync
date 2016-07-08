require 'docker_sync/sync_manager'

class Sync < Thor
  class_option :config, :aliases => '-c',:type => :string, :desc => 'Path of the docker_sync config'

  desc 'start', 'Start all sync configurations in this project'
  method_option :sync_name, :aliases => '-n',:type => :string, :desc => 'If given, only this sync configuration will be started'
  def start
    config_path = '/Users/em/Development/repos/docker_sync/test/config.yml'
    @sync_manager = Docker_Rsync::SyncManager.new(:config_path => config_path)
    @sync_manager.run(options[:sync_name])
  end

  desc 'sync_only', 'sync a specific sync configuration'
  method_option :sync_name, :aliases => '-n',:type => :string, :desc => 'If given, only this sync configuration will be started'
  def sync
    `touch /tmp/here`
    config_path = options[:config]
    @sync_manager = Docker_Rsync::SyncManager.new(:config_path => config_path)
    @sync_manager.sync(options[:sync_name])
  end
end
