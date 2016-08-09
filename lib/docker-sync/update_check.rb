require 'gem_update_checker'
require 'thor/actions'
require 'docker-sync/config'

class UpdateChecker
  include Thor::Shell
  @config
  def initialize
    @config = DockerSyncConfig::global_config
  end

  def run
    unless @config['update_check']
      say_status 'hint','Skipping up-to-date check since it has been disabled in your ~/.docker-sync-global.yml configuration',:yellow
      return
    end
    unless should_run
      return
    end
    check_rsync_image unless DockerSyncConfig::is_first_run # do not check the image if its the first run - since this it will be downloaded anyway
    check_unison_onesided_image unless DockerSyncConfig::is_first_run
    check_unison_image unless DockerSyncConfig::is_first_run
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

  def check_rsync_image
    say_status 'ok','Checking if a newer rsync image is available'

    if system("docker pull eugenmayer/rsync | grep 'Downloaded newer image for'")
      say_status 'warning', 'Downloaded newer image for rsync', :red
      say_status 'warning', 'Please use "docker-sync clean" before you start docker-sync again', :red

      exit 0
    end
    say_status 'success','Image is (now) up to date'
  end

  def check_unison_image
    say_status 'ok','Checking if a newer unison image is available'

    if system("docker pull eugenmayer/unison:unox | grep 'Downloaded newer image for'")
      say_status 'warning', 'Downloaded newer image for unison', :red
      say_status 'warning', 'Please use "docker-sync clean" before you start docker-sync again', :red

      exit 0
    end
    say_status 'success','Image is (now) up to date'
  end

  def check_unison_onesided_image
    say_status 'ok','Checking if a newer unison:onesided image is available'

    if system("docker pull eugenmayer/unison:onesided | grep 'Downloaded newer image for'")
      say_status 'warning', 'Downloaded newer image for unison:onesided', :red
      say_status 'warning', 'Please use "docker-sync clean" before you start docker-sync again', :red

      exit 0
    end
    say_status 'success','Image is (now) up to date'
  end

  def get_current_version
    path = File.expand_path('../../../', __FILE__)
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
    DockerSyncConfig::global_config_save(@config)

    check = docker_sync_update_check
    if check.update_available
      say_status 'warning',"There is an update (#{check.latest_version}) available (current version #{check.current_version}). Please update before you continue",:yellow
      if yes?("Shall i update docker-sync to #{check.latest_version} for you?")
        system('gem update docker-sync')
        say_status 'success','Successfully updated, please restart docker-sync and check the changelog at https://github.com/EugenMayer/docker-sync/wiki/5.-Changelog',:green
        exit 0
      else
        exit 1 if update_enforced
      end
    end
  end
end