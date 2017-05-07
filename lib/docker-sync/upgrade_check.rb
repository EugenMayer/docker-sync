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
    return File.read("#{path}/VERSION")
  end

  def docker_sync_update_check
    gem_name = 'docker-sync'
    current_version = UpgradeChecker.get_current_version
    checker = GemUpdateChecker::Client.new(gem_name, current_version)
    return checker
  end

  def check_and_warn
    # this is the upgrade hook for the unison-unox introduction / rename of unison
    if Gem::Version.new(last_upgraded_version) <  Gem::Version.new('0.1.0')
      Thor::Shell::Basic.new.say_status 'warning', 'Please be aware that with the strategy "unison" is now called unison-onesided and you might need to migrate. See https://github.com/EugenMayer/docker-sync/wiki/Migration-Guide for more informations', :red
      unless Thor::Shell::Basic.new.yes?('Shall we continue? (y/N)')
        exit 1
      end
    end

    if Gem::Version.new(last_upgraded_version) <  Gem::Version.new('0.2.0')
      Thor::Shell::Basic.new.say_status 'warning', "A lot changed with 0.2.x! Unison is the default sync, unison-onesided has been REMOVED. If you have been using rsync, have been using unison excludes or you are not sure, please read the upgrade guide or your setup will go lala! : \n\n_Please_ read :): https://github.com/EugenMayer/docker-sync/wiki/1.2-Upgrade-Guide\n\n", :red
      unless Thor::Shell::Basic.new.yes?('Shall we continue - DID you read it? (y/N)')
        exit 1
      end
    end

    if Gem::Version.new(last_upgraded_version) <  Gem::Version.new('0.3.0')
      Thor::Shell::Basic.new.say_status 'warning', "The installation progress of docker-sync 0.3.0 has changed, brew is now mandatory - you need to uninstall unox ! : \n\n_Please_ read :): https://github.com/EugenMayer/docker-sync/wiki/1.2-Upgrade-Guide\n\n", :red

      cmd1 = 'sudo rm -f /usr/local/bin/unison-fsmonitor && brew tap eugenmayer/dockersync && brew install eugenmayer/dockersync/unox'
      Thor::Shell::Basic.new.say_status 'ok', cmd1, :rwhite

      if Thor::Shell::Basic.new.yes?('I will reinstall unox for you using the above command (y/N)')
        system cmd1
      else
        raise('Please reinstall docker-sync yourself')
        exit 1
      end
    end

    if Gem::Version.new(last_upgraded_version) <  Gem::Version.new('0.4.0')
      Thor::Shell::Basic.new.say_status 'warning', "docker-sync has a new superior default sync strategy native_osx - consider switching to it no matter if you used unison or rsync. \nIt does no longer need Unison/Unox on OSX - no brew needed either. And its a lot thriftier ! \n\n_Please_ read :): https://github.com/EugenMayer/docker-sync/wiki/1.2-Upgrade-Guide\n\n", :red

      unless Thor::Shell::Basic.new.yes?('Shall we continue - DID you read it - really :) ? (y/N)')
        exit 1
      end
    end

    if Gem::Version.new(last_upgraded_version) <  Gem::Version.new('0.4.1')
      Thor::Shell::Basic.new.say_status 'warning', "Please add :nocopy to every named-volume mount you defined in your docker-compose-dev.yml! \n\nWhy? : https://github.com/EugenMayer/docker-sync/wiki/2.-Configuration#why-nocopy-is-important\n\n", :red

      unless Thor::Shell::Basic.new.yes?('Did you fix your docker-compose-dev.yml? (y/N)')
        exit 1
      end
    end

    if Gem::Version.new(last_upgraded_version) <  Gem::Version.new('0.4.2')
      checker = UpdateChecker.new
      checker.check_unison_hostsync_image

      Thor::Shell::Basic.new.say_status 'warning', "The native_osx is NOW ONLY for docker-for-mac, this is due to https://github.com/EugenMayer/docker-sync/issues/346\n\nThat means that unison is picked as a default automatically if you use docker-machine", :red

      unless Thor::Shell::Basic.new.yes?('Just wanted you to know that! (y/N)')
        exit 1
      end
    end

    if Gem::Version.new(last_upgraded_version) <  Gem::Version.new('0.4.3')
      checker = UpdateChecker.new
      checker.check_unison_hostsync_image
    end

    # update the upgrade_status
    @config.update! 'upgrade_status' => "#{UpgradeChecker.get_current_version}"
  end
end
