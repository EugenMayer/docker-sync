require 'docker-sync/sync_manager'
require 'docker-sync/config'
require 'docker-sync/preconditions'
require 'docker-sync/update_check'
require 'docker-sync/upgrade_check'
require 'daemons'
require 'fileutils'

class Sync < Thor

  class_option :config, :aliases => '-c',:default => nil, :type => :string, :desc => 'Path of the docker_sync config'
  class_option :sync_name, :aliases => '-n',:type => :string, :desc => 'If given, only this sync configuration will be references/started/synced'
  class_option :version, :aliases => '-v',:type => :boolean, :default => false, :desc => 'prints out the version of docker-sync and exits'

  desc 'start', 'Start all sync configurations in this project'
  method_option :daemon, :aliases => '-d', :default => false, :type => :boolean, :desc => 'Run in the background'
  method_option :app_name, :aliases => '--name', :default => 'daemon', :type => :string, :desc => 'App name used in PID and OUTPUT file name for Daemon'
  method_option :dir, :aliases => '--dir', :default => './.docker-sync', :type => :string, :desc => 'Path to PID and OUTPUT file Directory'
  method_option :logd, :aliases => '--logd', :default => true, :type => :boolean, :desc => 'To log OUPUT to file on Daemon or not'
  def start
    if options[:version]
      puts UpgradeChecker.get_current_version
      exit(0)
    end

    # do run update check in the start command only
    UpdateChecker.new().run
    UpgradeChecker.new().run


    config_path = config_preconditions # Preconditions and Define config_path from shared method
    @sync_manager = Docker_sync::SyncManager.new(:config_path => config_path)

    start_dir = Dir.pwd # Set start_dir variable to be equal to pre-daemonized folder, since daemonizing will change dir to '/'
    if options['daemon']
      daemonize
    else
      say_status 'note:', 'You can also run docker-sync in the background with --daemon'
    end

    Dir.chdir(start_dir) do # We want run these in pre-daemonized folder/directory since provided config_path might not be full_path
      @sync_manager.run(options[:sync_name])
      @sync_manager.join_threads
    end
  end

  desc 'stop', 'Stop docker-sync daemon'
  method_option :app_name, :aliases => '--name', :default => 'daemon', :type => :string, :desc => 'App name used in PID and OUTPUT file name for Daemon'
  method_option :dir, :aliases => '--dir', :default => './.docker-sync', :type => :string, :desc => 'Path to PID and OUTPUT file Directory'
  def stop
    if options[:version]
      puts UpgradeChecker.get_current_version
      exit(0)
    end

    config_path = config_preconditions
    sync_manager = Docker_sync::SyncManager.new(:config_path => config_path)

    begin
      pid = File.read("#{options['dir']}/#{options['app_name']}.pid") # Read PID from PIDFILE created by Daemons
      Process.kill(:INT, -(Process.getpgid(pid.to_i))) # Send INT signal to group PID, which means INT will be sent to all sub-processes and Threads spawned by docker-sync
      say_status 'shutdown', 'Background dsync has been stopped'
    rescue Errno::ESRCH, Errno::ENOENT => e
      say_status 'error', e.message, :red # Rescue incase PIDFILE does not exist or there is no process with such PID
      say_status(
        'error', 'Check if your PIDFILE and process with such PID exists', :red
      )
    end
  end

  desc 'sync', 'sync - do not start a watcher'
  def sync
    if options[:version]
      puts UpgradeChecker.get_current_version
      exit(0)
    end

    config_path = config_preconditions # Preconditions and Define config_path from shared method

    @sync_manager = Docker_sync::SyncManager.new(:config_path => config_path)
    @sync_manager.sync(options[:sync_name])
  end

  desc 'clean', 'Stop and clean up all sync endpoints'
  def clean
    if options[:version]
      puts UpgradeChecker.get_current_version
      exit(0)
    end

    config_path = config_preconditions # Preconditions and Define config_path from shared method

    # Look for any background syncs and stop them if we see them
    dir = './.docker-sync'
    files = Dir[File.join(dir, '*.pid')]
    files.each do |pid_file|
      pid = File.read(pid_file).to_i
      Process.kill(:INT, -(Process.getpgid(pid)))
      say_status 'shutdown', 'Background dsync has been stopped'
    end
    # Remove the .docker-sync directory
    FileUtils.rm_r dir if File.directory?(dir)

    @sync_manager = Docker_sync::SyncManager.new(:config_path => config_path)
    @sync_manager.clean(options[:sync_name])
    say_status 'success', 'Finished cleanup. Removed stopped, removed sync container and removed their volumes', :green
  end

  desc 'list', 'List all sync-points of the project configuration path'
  method_option :verbose, :default => false, :type => :boolean, :desc => 'Verbose output'
  def list
    if options[:version]
      puts UpgradeChecker.get_current_version
      exit(0)
    end

    config_path = config_preconditions # Preconditions and Define config_path from shared method

    say_status 'ok',"Found configuration at #{config_path}"
    @sync_manager = Docker_sync::SyncManager.new(:config_path => config_path)
    @sync_manager.get_sync_points.each do |name, config|
      say_status name, "On address #{config['sync_host_ip']}:#{config['sync_host_port']}",:white unless options['verbose']
      puts "\n---------------[#{name}] #{config['sync_host_ip']}:#{config['sync_host_port']} ---------------\n" if options['verbose']
      print_table(config) if options['verbose']
    end
  end

  desc 'log', 'Prints last 100 lines of daemon log. Only for use with docker-sync started in background.'
  method_option :lines, :aliases => '--lines', :default => 100, :type => :numeric, :desc => "Specify number of lines to tail"
  method_option :app_name, :aliases => '--name', :default => 'daemon', :type => :string, :desc => 'App name used in PID and OUTPUT file name for Daemon'
  method_option :dir, :aliases => '--dir', :default => './.docker-sync', :type => :string, :desc => 'Path to PID and OUTPUT file Directory'
  method_option :follow, :aliases => '-f', :default => false, :type => :boolean, :desc => "Specify if the logs should be streamed"
  def log
    if options[:version]
      puts UpgradeChecker.get_current_version
      exit(0)
    end

    print_daemon_logs
  end

  no_tasks do
    def config_preconditions # Moved shared preconditions block into separate method to have less/cleaner code
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
      # Create the directory for the logs/pid if it doesn't already exist:
      FileUtils.mkpath(options['dir'])

      # Check to see if we're already running:
      if daemon_running?
        say_status 'error', "docker-sync already started for this configuration", :red
        exit 1
      end

      # If we're daemonizing, run a sync first to ensure the containers exist so that a docker-compose up won't fail:
      @sync_manager.start_container(options[:sync_name])
      # the existing strategies' start_container will also sync, but just in case a strategy doesn't, sync now:
      @sync_manager.sync(options[:sync_name])

      dopts = {
        app_name: options['app_name'],
        dir_mode: :normal,
        dir: options['dir'],
        log_output: options['logd'],
        output_logfilename: "#{options['app_name']}.log"
      } # List of options accepted by Daemonize, can be customized pretty nicely with provided CLI options

      say_status 'success', 'Starting Docker-Sync in the background', :green
      Daemons.daemonize(dopts)
    end

    def print_daemon_logs
      unless daemon_running?
        say_status 'error', "docker-sync is not running in daemon mode for this configuration", :red
        exit 1
      end

      log_file = File.join(options['dir'], "#{options['app_name']}.log")
      begin
        system("tail #{options['follow'] ? '-f ' : ''}-n #{options['lines']} #{log_file}")
      rescue Interrupt
        nil
      end
    end

    def daemon_running?
      pid_file = Daemons::PidFile.find_files(options['dir'], options['app_name']).first || ''

      File.file?(pid_file) && Daemons::Pid.running?(File.read(pid_file).to_i)
    end
  end
end
