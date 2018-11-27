require 'gem_update_checker'
require 'thor/actions'
require 'docker-sync/config/global_config'

class UpdateChecker
  include Thor::Shell
  @config
  @newer_image_found

  def initialize
    @config = DockerSync::GlobalConfig.load
    @newer_image_found = false
  end

  def run
    return if ENV['DOCKER_SYNC_SKIP_UPDATE']
    unless @config['update_check']
      say_status 'hint','Skipping up-to-date check since it has been disabled in your ~/.docker-sync-global.yml configuration',:yellow
      return
    end
    unless should_run
      return
    end

    # do not check the image if its the first run - since this it will be downloaded anyway
    unless @config.first_run?
      unless has_internet?
        check_rsync_image
        # stop if there was an update
        if @newer_image_found
          say_status 'warning', 'One or more images have been updated. Please use "docker-sync clean" before you start docker-sync again', :red
          exit 0
        end
      end
    end

    check_and_warn(@config['update_enforce'])
  end

  def has_internet?
    `ping -c1 -t 1 8.8.8.8 > /dev/null 2>&1`
    return $?.success?
  end

  def should_run
    return false unless has_internet?
    now = DateTime.now
    return true if @config['update_last_check'].nil?

    last_check = DateTime.iso8601(@config['update_last_check'])
    check_after_days = 2
    if now - last_check > check_after_days
      return true
    end

    return false
  end

  def check_rsync_image
    return if ENV['DOCKER_SYNC_SKIP_UPDATE']
    say_status 'ok','Checking if a newer rsync image is available'

    if system("docker pull eugenmayer/rsync | grep 'Downloaded newer image for'")
      say_status 'ok', 'Downloaded newer image for rsync', :green
      @newer_image_found = true
    else
      say_status 'ok', 'No newer image found - current image is up to date.'
    end

  end

  def get_current_version
    path = File.expand_path('../../../', __FILE__)
    version = File.read("#{path}/VERSION")
    version.strip
    version
  end

  def docker_sync_update_check
    gem_name = 'docker-sync'
    current_version = get_current_version
    checker = GemUpdateChecker::Client.new(gem_name, current_version)
    return checker
  end

  def check_and_warn(update_enforced = true)
    return if ENV['DOCKER_SYNC_SKIP_UPDATE']
    # update the timestamp
    @config.update! 'update_last_check' => DateTime.now.iso8601(9)

    check = docker_sync_update_check
    if check.update_available
      say_status 'warning',"There is an update (#{check.latest_version}) available (current version #{check.current_version}). Please update before you continue",:yellow
      if yes?("Shall I update docker-sync to #{check.latest_version} for you?")
        system('gem update docker-sync')
        say_status 'success','Successfully updated, please restart docker-sync and check the changelog at https://github.com/EugenMayer/docker-sync/wiki/5.-Changelog',:green
        exit 0
      else
        exit 1 if update_enforced
      end
    end
  end
end
