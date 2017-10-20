require 'docker-sync'
require 'docker-sync/sync_manager'
require 'docker-sync/update_check'
require 'docker-sync/upgrade_check'
require 'docker/compose'
require 'docker-sync/compose'
require 'docker-sync/config/project_config'

class Stack < Thor
  class_option :config, :aliases => '-c', :default => nil, :type => :string, :desc => 'Path of the docker_sync config'
  class_option :sync_name, :aliases => '-n', :type => :string, :desc => 'If given, only this sync configuration will be references/started/synced'
  class_option :version, :aliases => '-v',:type => :boolean, :default => false, :desc => 'prints out the version of docker-sync and exits'

  desc '--version, -v', 'Prints out the version of docker-sync and exits'
  def print_version
    puts UpgradeChecker.get_current_version
    exit(0)
  end
  map %w[--version -v] => :print_version

  desc 'start', 'Start sync services, watcher and then your docker-compose defined stack'
  def start
    if options[:version]
      puts UpgradeChecker.get_current_version
      exit(0)
    end

    # do run update check in the start command only
    updates = UpdateChecker.new
    updates.run

    upgrades = UpgradeChecker.new
    upgrades.run

    begin
      config = DockerSync::ProjectConfig.new(config_path: options[:config])
      DockerSync::Dependencies.ensure_all!(config)
    rescue StandardError => e
      say_status 'error', e.message, :red
      exit(1)
    end

    say_status 'note:', 'You can also run docker-sync in the background with docker-sync start'

    @sync_manager = DockerSync::SyncManager.new(config: config)
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
      rescue StandardError => e
        puts "EXCEPTION: #{e.inspect}"
        puts "MESSAGE: #{e.message}"
    end
  end

  desc 'clean', 'compose down your app stack, stop and clean up all sync endpoints'

  def clean
    if options[:version]
      puts UpgradeChecker.get_current_version
      exit(0)
    end

    begin
      config = DockerSync::ProjectConfig.new(config_path: options[:config])
      DockerSync::Dependencies.ensure_all!(config)
    rescue StandardError => e
      say_status 'error', e.message, :red
      exit(1)
    end

    @sync_manager = DockerSync::SyncManager.new(config: config)
    global_options = @sync_manager.global_options
    # shutdown compose first
    @compose_manager = ComposeManager.new(global_options)
    @compose_manager.clean
    say_status 'success', 'Finished cleaning up your app stack', :green

    # now shutdown sync
    @sync_manager.clean(options[:sync_name])
    say_status 'success', 'Finished cleanup. Removed stopped, removed sync container and removed their volumes', :green
  end
end
