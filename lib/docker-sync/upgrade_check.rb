require 'gem_update_checker'
require 'thor/actions'
require 'docker-sync/config/global_config'
require 'docker-sync/update_check'

class UpgradeChecker
  include Thor::Shell
  @config
  def initialize
    @config = DockerSync::GlobalConfig.load
  end

  def run
    return if ENV['DOCKER_SYNC_SKIP_UPGRADE']
    unless should_run
      return
    end
    check_and_warn
  end

  def last_upgraded_version
    @config['upgrade_status']
  end

  def should_run
    # get the update_status which is the version of the update hook which has been run already
    upgrade_status = last_upgraded_version
    if upgrade_status == ''
      @config.update! 'upgrade_status' => "#{UpgradeChecker.get_current_version}"
      return
    end

    if Gem::Version.new(upgrade_status) < Gem::Version.new(UpgradeChecker.get_current_version) # thats how we compare the version
      return true
    end

    return false
  end


  def self.get_current_version
    path = File.expand_path('../../../', __FILE__)
    version = File.read("#{path}/VERSION")
    version.strip
    version
  end

  def docker_sync_update_check
    gem_name = 'docker-sync'
    current_version = UpgradeChecker.get_current_version
    checker = GemUpdateChecker::Client.new(gem_name, current_version)
    return checker
  end

  def check_and_warn
    return if ENV['DOCKER_SYNC_SKIP_UPGRADE']

    if Gem::Version.new(last_upgraded_version) <  Gem::Version.new('0.5.6')
      Thor::Shell::Basic.new.say_status 'warning', "If you are upgrading from 0.5.4 or below, please run `brew update && brew upgrade unison` AND `docker-compose down && docker-sync clean` or `docker-sync-stack clean` since you need to recreate the sync container", :red

      unless Thor::Shell::Basic.new.yes?('Sync will fail otherwise. Continue? (y/N)')
        exit 1
      end
    end

    # update the upgrade_status
    @config.update! 'upgrade_status' => "#{UpgradeChecker.get_current_version}"
  end
end
