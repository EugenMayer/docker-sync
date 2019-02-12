module DockerSync
  module Dependencies
    module Docker
      module Driver
        def self.docker_for_mac?
          return false unless Environment.mac?
          return @docker_for_mac if defined? @docker_for_mac
          @docker_for_mac = Environment.system('pgrep -q com.docker.hyperkit')
        end

        def self.docker_toolbox?
          return false unless Environment.mac? || Environment.freebsd?
          return false unless find_executable0('docker-machine')
          return @docker_toolbox if defined? @docker_toolbox
          @docker_toolbox = Environment.system('docker info | grep -q "Operating System: Boot2Docker"')
        end
      end
    end
  end
end
