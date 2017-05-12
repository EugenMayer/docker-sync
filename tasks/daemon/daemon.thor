require 'docker-sync'
require 'docker-sync/sync_manager'
require 'docker-sync/update_check'
require 'docker-sync/upgrade_check'
require 'daemons'
require 'fileutils'

class Daemon < Thor
  class_option :dir, :aliases => '--dir', :default => './.docker-sync', :type => :string, :desc => 'Path to PID and OUTPUT file Directory'
  class_option :logd, :aliases => '--logd', :default => true, :type => :boolean, :desc => 'To log OUPUT to file on Daemon or not'
  class_option :app_name, :aliases => '--name', :default => 'daemon', :type => :string, :desc => 'App name used in PID and OUTPUT file name for Daemon'
  class_option :logd, :aliases => '--logd', :default => true, :type => :boolean, :desc => 'To log OUPUT to file on Daemon or not'
  class_option :config, :aliases => '-c',:default => nil, :type => :string, :desc => 'Path of the docker_sync config'
  class_option :sync_name, :aliases => '-n',:type => :string, :desc => 'If given, only this sync configuration will be references/started/synced'
  class_option :version, :aliases => '-v',:type => :boolean, :default => false, :desc => 'prints out the version of docker-sync and exits'

  desc 'start', 'Start docker-sync daemon'
  def start
    say_status 'warning', 'Daemon mode is now the default, just use docker-sync start .. docker-sync-daemon is deprecated', :blue

    opt = options.dup
    opt.merge!(:daemon => true)
    sync = Sync.new([], opt)
    sync.start
  end

  desc 'stop', 'Stop docker-sync daemon'
  def stop
    say_status 'warning', 'Daemon mode is now the default, just use docker-sync start .. docker-sync-daemon is deprecated', :blue

    opt = options.dup
    opt.merge!(:daemon => true)
    sync = Sync.new([], opt)
    sync.stop
  end

  desc 'clean', 'Clean docker-sync daemon'
  def clean
    say_status 'warning', 'Daemon mode is now the default, just use docker-sync start .. docker-sync-daemon is deprecated', :blue

    opt = options.dup
    opt.merge!(:daemon => true)
    sync = Sync.new([], opt)
    sync.clean
  end

  desc 'logs', 'Prints last 100 lines of daemon log. Only for use with docker-sync started in background.'
  method_option :lines, :aliases => '--lines', :default => 100, :type => :numeric, :desc => 'Specify number of lines to tail'
  method_option :follow, :aliases => '-f', :default => false, :type => :boolean, :desc => 'Specify if the logs should be streamed'
  def logs
    opt = options.dup
    sync = Sync.new([], opt)
    sync.logs
  end
end
