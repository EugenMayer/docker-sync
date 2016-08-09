require 'gem_update_checker'
require 'thor/actions'
require 'docker-sync/config'

class UpgradeChecker
  include Thor::Shell
  @config
  def initialize
    @config = DockerSyncConfig::global_config
  end

  def run
    unless should_run
      return
    end
    check_and_warn
  end

  def last_upgraded_version
    @config['upgrade_status'] || ''
  end

  def should_run
    # get the update_status which is the version of the update hook which has been run already
    upgrade_status = last_upgraded_version
    if upgrade_status == '' || Gem::Version.new(upgrade_status) < Gem::Version.new(get_current_version) # thats how we compare the version
      return true
    end

    return false
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

  def check_and_warn
    # this is the upgrade hook for the unison-unox introduction / rename of unison
    if Gem::Version.new(last_upgraded_version) <  Gem::Version.new('0.1.0')
      Thor::Shell::Basic.new.say_status 'warning', 'Please be aware that with the strategy "unison" is now called unison-onesided and you might need to migrate. See https://github.com/EugenMayer/docker-sync/wiki/Migration-Guide for more informations', :red
      unless Thor::Shell::Basic.new.yes?('Shall we continue?')
        exit 1
      end
    end

    # update the upgrade_status
    @config['upgrade_status'] = "#{get_current_version}"
    DockerSyncConfig::global_config_save(@config)
  end
end