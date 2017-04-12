require 'mkmf'

module Preconditions
  def self.check_all_preconditions
    docker_available
    docker_running
    unison_available
    unox_available
    watchdog_available
  end

  def self.docker_available
    if (find_executable0 'docker').nil?
      raise('Could not find docker binary in path. Please install it, e.g. using "brew install docker" or install docker-for-mac')
    end
  end

  def self.docker_running
    `docker ps`
    if $?.exitstatus > 0
      raise('No docker daemon seems to be running. Did you start your docker-for-mac / docker-machine?')
    end
  end

  def self.fswatch_available
    if (find_executable0 'fswatch').nil?
      raise('No fswatch available. Install it by "brew install fswatch"')
    end
  end

  def self.docker_sync_available
    if (find_executable0 'docker-sync').nil?
      raise('No docker-sync available. Install it by "gem install docker-sync"')
    end
  end

  def self.rsync_available
    if (find_executable0 'rsync').nil?
      raise('Could not find rsync binary in path. Please install it, e.g. using "brew install rsync"')
    end
  end

  def self.unison_available
    if (find_executable0 'unison').nil?
      raise('Could not find unison binary in path. Please install it, e.g. using "brew install unison"')
    end
  end

  def self.unox_available
    if (find_executable0 'unison-fsmonitor').nil?
      cmd1 = 'curl "https://raw.githubusercontent.com/hnsl/unox/master/unox.py" -o "/usr/local/bin/unison-fsmonitor" \
      && chmod +x /usr/local/bin/unison-fsmonitor'

      Thor::Shell::Basic.new.say_status 'warning', 'Could not find unison-fsmonitor (for file watching) binary in $PATH. We try to install unox now (for manual instracutions see https://github.com/hnsl/unox.)', :red
      if Thor::Shell::Basic.new.yes?('Shall I install unison-fsmonitor for you? (y/N)')
        system cmd1
      else
        raise("Please install it, see https://github.com/hnsl/unox, or simply run :\n #{cmd1}")
      end
    end

  end

  def self.watchdog_available
    `python -c 'from watchdog.observers import Observer'`
    unless $?.success?
      Thor::Shell::Basic.new.say_status 'warning','Could not find watchdog. Will try to install it using pip', :red
      if find_executable0('python') == '/usr/bin/python'
        Thor::Shell::Basic.new.say_status 'ok','You seem to use the system python, we will need sudo below'
        sudo = true
        cmd2 = 'sudo easy_install pip && sudo pip install watchdog'
      else
        Thor::Shell::Basic.new.say_status 'ok','You seem to have a custom python, using non-sudo commands'
        sudo = false
        cmd2 = 'easy_install pip && pip install watchdog'
      end
      if sudo
        question = 'I will ask you for you root password to install macfsevent by running (This will ask for sudo, since we use the system python)'
      else
        question = 'I will now install watchdog for you by running'
      end

      Thor::Shell::Basic.new.say_status 'info', "#{question}: `#{cmd2}\n\n"
      if Thor::Shell::Basic.new.yes?('Shall i continue? (y/N)')
        system cmd2
        if $?.exitstatus > 0
          raise('Failed to install watchdog, please file an issue with the output of the error')
        end
        `python -c 'import fsevents'`
        unless $?.success?
          raise('Somehow could not successfully install watchdog even though i treed. Please report this issue')
        end
      else
        raise('Please install watchdog manually, see https://github.com/EugenMayer/docker-sync/wiki/1.-Installation')
      end
    end


  end
end
