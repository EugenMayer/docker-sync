require 'docker-sync'
require 'docker-sync/sync_manager'
require 'docker-sync/update_check'
require 'docker-sync/upgrade_check'
require 'daemons'
require 'fileutils'
require 'docker-sync/config/project_config'
require 'timeout'

class Sync < Thor

  class_option :config, :aliases => '-c',:default => nil, :type => :string, :desc => 'Path of the docker_sync config'
  class_option :sync_name, :aliases => '-n',:type => :string, :desc => 'If given, only this sync configuration will be references/started/synced'
  class_option :version, :aliases => '-v',:type => :boolean, :default => false, :desc => 'prints out the version of docker-sync and exits'

  desc '--version, -v', 'Prints out the version of docker-sync and exits'
  def print_version
    puts UpgradeChecker.get_current_version
    exit(0)
  end
  map %w[--version -v] => :print_version

  desc 'start', 'Start all sync configurations in this project'
  method_option :daemon, :aliases => '-d', :default => false, :type => :boolean, :desc => 'Run in the background'
  method_option :foreground, :aliases => '-f', :default => false, :type => :boolean, :desc => 'Run in the foreground'
  method_option :app_name, :aliases => '--name', :default => 'daemon', :type => :string, :desc => 'App name used in PID and OUTPUT file name for Daemon'
  method_option :dir, :aliases => '--dir', :default => './.docker-sync', :type => :string, :desc => 'Path to PID and OUTPUT file Directory'
  method_option :logd, :aliases => '--logd', :default => true, :type => :boolean, :desc => 'To log OUPUT to file on Daemon or not'
  def start
    print_version if options[:version]
    # do run update check in the start command only
    UpdateChecker.new.run
    UpgradeChecker.new.run

    config = config_preconditions
    @sync_manager = DockerSync::SyncManager.new(config: config)

    start_dir = Dir.pwd # Set start_dir variable to be equal to pre-daemonized folder, since daemonizing will change dir to '/'

    if  options['daemon']
      puts 'WARNING: --daemon is deprecated and now the default. Just start without --daemon'
    end

    if options['foreground']
      say_status 'note:', 'Starting in foreground mode', :white
    else
      daemonize
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
    print_version if options[:version]

    config = config_preconditions
    sync_manager = DockerSync::SyncManager.new(config: config)
    sync_manager.stop
    pid_file_path="#{options['dir']}/#{options['app_name']}.pid"
    if File.exist?(pid_file_path)
      begin
        pid = File.read("#{options['dir']}/#{options['app_name']}.pid") # Read PID from PIDFILE created by Daemons
        Process.kill(:INT, -(Process.getpgid(pid.to_i))) # Send INT signal to group PID, which means INT will be sent to all sub-processes and Threads spawned by docker-sync
        wait_for_process_termination(pid.to_i)
      rescue Errno::ESRCH, Errno::ENOENT => e
        say_status 'error', e.message, :red # Rescue incase PIDFILE does not exist or there is no process with such PID
        say_status 'error', 'Check if your PIDFILE and process with such PID exists', :red
        exit(69) # EX_UNAVAILABLE (see `man sysexits` or `/usr/include/sysexits.h`)
      end
    else
      # there was no watcher started / needed, e.g. dummy. Nothing to worry about
    end

  end

  desc 'sync', 'just sync - do not start a watcher though'
  def sync
    print_version if options[:version]

    config = config_preconditions

    @sync_manager = DockerSync::SyncManager.new(config: config)
    @sync_manager.sync(options[:sync_name])
  end

  desc 'clean', 'Stop and clean up all sync endpoints'
  def clean
    print_version if options[:version]

    config = config_preconditions

    # Look for any background syncs and stop them if we see them
    dir = './.docker-sync'
    files = Dir[File.join(dir, '*.pid')]
    files.each do |pid_file|
      pid = File.read(pid_file).to_i
      Process.kill(:INT, -(Process.getpgid(pid))) if Daemons::Pid.running?(pid)
      say_status 'shutdown', 'Background sync has been stopped'
    end
    # Remove the .docker-sync directory
    FileUtils.rm_r dir if File.directory?(dir)

    @sync_manager = DockerSync::SyncManager.new(config: config)
    @sync_manager.clean(options[:sync_name])
    say_status 'success', 'Finished cleanup. Removed stopped, removed sync container and removed their volumes', :green
  end

  desc 'logs', 'Prints last 100 lines of daemon log. Only for use with docker-sync started in background.'
  method_option :lines, :aliases => '--lines', :default => 100, :type => :numeric, :desc => 'Specify number of lines to tail'
  method_option :follow, :aliases => '-f', :default => false, :type => :boolean, :desc => 'Specify if the logs should be streamed'
  method_option :dir, :aliases => '--dir', :default => './.docker-sync', :type => :string, :desc => 'Path to PID and OUTPUT file Directory'
  method_option :logd, :aliases => '--logd', :default => true, :type => :boolean, :desc => 'To log OUPUT to file on Daemon or not'
  method_option :app_name, :aliases => '--name', :default => 'daemon', :type => :string, :desc => 'App name used in PID and OUTPUT file name for Daemon'
  def logs
    print_version if options[:version]

    print_daemon_logs
  end

  desc 'list', 'List all sync-points of the project configuration path'
  method_option :verbose, :default => false, :type => :boolean, :desc => 'Verbose output'
  def list
    print_version if options[:version]

    project_config = config_preconditions

    say_status 'ok',"Found configuration at #{project_config.config_path}"
    @sync_manager = DockerSync::SyncManager.new(config: project_config)
    @sync_manager.get_sync_points.each do |name, sync_config|
      say_status name, "On address #{sync_config['sync_host_ip']}:#{sync_config['sync_host_port']}",:white unless options['verbose']
      puts "\n---------------[#{name}] #{sync_config['sync_host_ip']}:#{sync_config['sync_host_port']} ---------------\n" if options['verbose']
      print_table(sync_config) if options['verbose']
    end
  end

  no_tasks do
    def config_preconditions # Moved shared preconditions block into separate method to have less/cleaner code
      DockerSync::ProjectConfig.new(config_path: options[:config]).tap do |config|
        DockerSync::Dependencies.ensure_all!(config)
      end
    rescue StandardError => e
      say_status 'error', e.message, :red
      exit 1
    end

    def daemonize
      # Create the directory for the logs/pid if it doesn't already exist:
      FileUtils.mkpath(options['dir'])

      # Check to see if we're already running:
      if daemon_running?
        say_status 'ok:', 'docker-sync already started for this configuration', :white
        exit 0
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

    def wait_for_process_termination(pid)
      print 'Waiting for background docker-sync to terminate'
      Timeout::timeout(30) do
        loop do
          if process_dead?(pid)
            puts
            say_status 'shutdown', 'Background docker-sync has been stopped'
            return
          else
            sleep 1
            print '.'
          end
        end
      end
    rescue Timeout::Error
      puts
      say_status 'error', 'Background docker-sync daemon failed to stop within 30 seconds', :red
      exit 70 # EX_SOFTWARE (according to `man sysexits`)
    end

    def process_dead?(pid)
      !system("ps -p #{pid} > /dev/null")
    end
  end
end
