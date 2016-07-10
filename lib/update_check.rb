require 'gem_update_checker'
require 'thor/actions'
require 'config'

class UpdateChecker
  include Thor::Shell
  include DockerSyncConfig
  @config
  def initialize
    @config = global_config
  end

  def run
    unless @config['update_check']
      say_status 'hint','Skipping up-to-date check since it has been disabled in yout ~/.docker-sync-global.yml configuration',:yellow
      return
    end
    unless should_run
      return
    end
    check_and_warn(@config['update_enforce'])
  end

  def should_run
    now = DateTime.now
    last_check = DateTime.iso8601(@config['update_last_check'])
    check_after_days = 2
    if now - last_check > check_after_days
      return true
    end

    return false
  end

  def get_current_version
    path = File.expand_path('../../', __FILE__)
    return File.read("#{path}/VERSION")
  end

  def docker_sync_update_check
    gem_name = 'docker-sync'
    current_version = get_current_version
    checker = GemUpdateChecker::Client.new(gem_name, current_version)
    return checker
  end

  def check_and_warn(update_enforced = true)
    # update the timestamp
    now = DateTime.now
    @config['update_last_check'] = now.iso8601(9)
    global_config_save(@config)

    check = docker_sync_update_check
    if check.update_available
      say_status 'warning',"There is an update (#{check.latest_version}) available (current version #{check.current_version}). Please update before you continue",:yellow
      if yes?("Shall i update docker-sync to #{check.latest_version} for you?")
        system('gem update docker-sync')
      else
        exit 1 if update_enforced
      end
    end
  end
end