module DockerSync
  module Dependencies
    module Docker
      DOCKER_NOT_AVAILABLE = 'Could not find Docker. Please install it (see https://docs.docker.com/compose/install/) and try again.'.freeze
      DOCKER_NOT_RUNNING   = 'No docker daemon seems to be running. Did you start docker-engine / docker-for-mac / docker-machine?'.freeze

      def self.available?
        return @available if defined? @available
        @available = find_executable0('docker')
      end

      def self.running?
        return @running if defined? @running
        @running = system('docker ps 2>&1 > /dev/null')
      end

      def self.ensure!
        raise(DOCKER_NOT_AVAILABLE) unless available?
        raise(DOCKER_NOT_RUNNING)   unless running?
      end
    end
  end
end
