require 'docker-sync/sync_manager'
require 'docker-sync/config'
require 'docker-sync/preconditions'
require 'docker-sync/update_check'
require 'daemons'

class Sync < Thor

  class_option :config, :aliases => '-c',:default => nil, :type => :string, :desc => 'Path of the docker_sync config'
  class_option :sync_name, :aliases => '-n',:type => :string, :desc => 'If given, only this sync configuration will be references/started/synced'

  desc 'start', 'Start all sync configurations in this project'
  method_option :daemon, :aliases => '-d', :default => false, :type => :boolean, :desc => 'Run in the background'
  method_option :app_name, :aliases => '--name', :default => 'dsync', :type => :string, :desc => 'App name used in PID and OUTPUT file name for Daemon'
  method_option :dir, :aliases => '--dir', :default => '/tmp', :type => :string, :desc => 'Full path to PID and OUTPUT file Directory'
  method_option :logd, :aliases => '--logd', :default => true, :type => :boolean, :desc => 'To log OUPUT to file on Daemon or not'
  def start
    # do run update check in the start command only
    UpdateChecker.new().run

    config_path = config_preconditions

    start_dir = Dir.pwd
    daemonize if options['daemon']

    Dir.chdir(start_dir) do
      @sync_manager = Docker_Rsync::SyncManager.new(:config_path => config_path)
      @sync_manager.run(options[:sync_name])
      @sync_manager.join_threads
    end
  end

  desc 'stop', 'Stop docker-sync daemon'
  method_option :app_name, :aliases => '--name', :default => 'dsync', :type => :string, :desc => 'App name used in PID and OUTPUT file name for Daemon'
  method_option :dir, :aliases => '--dir', :default => '/tmp', :type => :string, :desc => 'Full path to PID and OUTPUT file Directory'
  def stop
    config_preconditions

    begin
      pid = File.read("#{options['dir']}/#{options['app_name']}.pid")
      # Send INT signal to all processes in given Group PID
      Process.kill(:INT, -(Process.getpgid(pid.to_i)))
      say_status 'shutdown', 'Background dsync has been stopped'
    rescue Errno::ESRCH, Errno::ENOENT => e
      say_status 'error', e.message, :red
      say_status(
        'error', 'Check if your PIDFILE and process with such PID exists', :red
      )
    end
  end

  desc 'sync', 'sync - do not start a watcher'
  def sync
    config_path = config_preconditions

    @sync_manager = Docker_Rsync::SyncManager.new(:config_path => config_path)
    @sync_manager.sync(options[:sync_name])
  end

  desc 'clean', 'Stop and clean up all sync endpoints'
  def clean
    config_path = config_preconditions

    @sync_manager = Docker_Rsync::SyncManager.new(:config_path => config_path)
    @sync_manager.clean(options[:sync_name])
    say_status 'success', 'Finished cleanup. Removed stopped, removed sync container and removed there volumes', :green
  end

  desc 'list', 'List all sync-points of the project configuration path'
  method_option :verbose, :default => false, :type => :boolean, :desc => 'Verbose output'
  def list
    config_path = config_preconditions

    say_status 'ok',"Found configuration at #{config_path}"
    @sync_manager = Docker_Rsync::SyncManager.new(:config_path => config_path)
    @sync_manager.get_sync_points.each do |name, config|
      say_status name, "On address #{config['sync_host_ip']}:#{config['sync_host_port']}",:white unless options['verbose']
      puts "\n---------------[#{name}] #{config['sync_host_ip']}:#{config['sync_host_port']} ---------------\n" if options['verbose']
      print_table(config) if options['verbose']
    end
  end

  no_tasks do
    def config_preconditions
      begin
        Preconditions::check_all_preconditions
      rescue Exception => e
        say_status 'error', e.message, :red
        exit 1
      end

      return options[:config] if options[:config]

      begin
        DockerSyncConfig::project_config_path
      rescue Exception => e
        say_status 'error', e.message, :red
        exit 1
      end
    end

    def daemonize
      dopts = {
        app_name: options['app_name'],
        dir_mode: :normal,
        dir: options['dir'],
        log_output: options['logd']
      }

      say_status 'success', 'Starting Docker-Sync in the background', :green
      Daemons.daemonize(dopts)
    end
  end
end
