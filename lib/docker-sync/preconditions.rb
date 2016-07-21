require 'mkmf'

module Preconditions
  def self.check_all_preconditions
    docker_available
    docker_running
    fswatch_available
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
      raise('Could not find unison-fsmonitor binary in path. Please install it, see https://github.com/hnsl/unox')
    end
  end
end