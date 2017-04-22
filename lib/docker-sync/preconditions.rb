require 'mkmf'

module Preconditions
  def self.check_all_preconditions(config)
    docker_available
    docker_running

    if config.unison_required?
      unison_available
      unox_available
      macfsevents_available
      watchdog_available
    end
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

  def self.macfsevents_available
    install_pip 'macfsevents', 'fsevents'
  end

  def self.watchdog_available
    install_pip 'watchdog'
  end

  def self.install_pip(package, test = nil)
    test ? `python -c 'import #{test}'` : `python -c 'import #{package}'`

    unless $?.success?
      Thor::Shell::Basic.new.say_status 'warning', "Could not find #{package}. Will try to install it using pip", :red
      if find_executable0('python') == '/usr/bin/python'
        Thor::Shell::Basic.new.say_status 'ok', 'You seem to use the system python, we will need sudo below'
        sudo = true
        cmd2 = "sudo easy_install pip && sudo pip install #{package}"
      else
        Thor::Shell::Basic.new.say_status 'ok', 'You seem to have a custom python, using non-sudo commands'
        sudo = false
        cmd2 = "easy_install pip && pip install #{package}"
      end
      if sudo
        question = "I will ask you for you root password to install #{package} by running (This will ask for sudo, since we use the system python)"
      else
        question = "I will now install #{package} for you by running"
      end

      Thor::Shell::Basic.new.say_status 'info', "#{question}: `#{cmd2}\n\n"
      if Thor::Shell::Basic.new.yes?('Shall I continue? (y/N)')
        system cmd2
        if $?.exitstatus > 0
          raise("Failed to install #{package}, please file an issue with the output of the error")
        end
        test ? `python -c 'import #{test}'` : `python -c 'import #{package}'`
        unless $?.success?
          raise("Somehow I could not successfully install #{package} even though I tried. Please report this issue.")
        end
      else
        raise("Please install #{package} manually, see https://github.com/EugenMayer/docker-sync/wiki/1.-Installation")
      end
    end
  end

end
