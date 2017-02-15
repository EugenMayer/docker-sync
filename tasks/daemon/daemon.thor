class Daemon < Thor
  default_task :start

  class_option :config, :aliases => '-c',:default => nil, :type => :string, :desc => 'Path of the docker_sync config'
  class_option :sync_name, :aliases => '-n',:type => :string, :desc => 'If given, only this sync configuration will be references/started/synced'

  desc 'start', 'Start all sync configurations in this project'
  method_option :daemon, :aliases => '-d', :default => false, :type => :boolean, :desc => 'Run in the background'
  method_option :app_name, :aliases => '--name', :default => 'daemon', :type => :string, :desc => 'App name used in PID and OUTPUT file name for Daemon'
  method_option :dir, :aliases => '--dir', :default => './.docker-sync', :type => :string, :desc => 'Path to PID and OUTPUT file Directory'
  method_option :logd, :aliases => '--logd', :default => true, :type => :boolean, :desc => 'To log OUPUT to file on Daemon or not'
  def start
    modified = options.dup
    modified[:daemon] = true
    invoke 'sync:start', [], modified
  end

  desc 'stop', 'Stop docker-sync daemon'
  method_option :app_name, :aliases => '--name', :default => 'daemon', :type => :string, :desc => 'App name used in PID and OUTPUT file name for Daemon'
  method_option :dir, :aliases => '--dir', :default => './.docker-sync', :type => :string, :desc => 'Path to PID and OUTPUT file Directory'
  def stop
    invoke 'sync:stop'
  end
end
