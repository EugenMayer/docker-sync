module DockerSync
  module Dependencies
    module Docker
      DOCKER_NOT_AVAILABLE = 'Could not find docker binary in path. Please install it, e.g. using "brew install docker" or install docker-for-mac'.freeze
      DOCKER_NOT_RUNNING   = 'No docker daemon seems to be running. Did you start your docker-for-mac / docker-machine?'.freeze

      def self.available?
        return @available if defined? @available
        @available = find_executable0('docker')
      end

      def self.running?
        return @running if defined? @running
        @running = system('docker ps &> /dev/null')
      end

      def self.ensure!
        raise(DOCKER_NOT_AVAILABLE) unless available?
        raise(DOCKER_NOT_RUNNING)   unless running?
      end
    end
  end
end
