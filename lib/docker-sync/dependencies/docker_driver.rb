module DockerSync
  module Dependencies
    module Docker
      module Driver
        def self.docker_on_mac?
          return false unless Environment.mac?
          return @docker_on_mac if defined? @docker_on_mac

          @docker_on_mac = docker_desktop? || docker_for_mac?
        end

        def self.docker_toolbox?
          return false unless Environment.mac? || Environment.freebsd?
          return false unless find_executable0('docker-machine')
          return @docker_toolbox if defined? @docker_toolbox
          @docker_toolbox = Environment.system('docker info | grep -q "Operating System: Boot2Docker"')
        end

        private

        def self.docker_for_mac?
          # com.docker.hyperkit for old virtualization engine
          # com.docker.virtualization for new virtualization engine
          # see https://docs.docker.com/desktop/mac/#enable-the-new-apple-virtualization-framework
          Environment.system('pgrep -q com.docker.hyperkit') || Environment.system('pgrep -q com.docker.virtualization')
        end

        def self.docker_desktop?
          # detect if using docker desktop
          Environment.system('docker info | grep -q "Operating System: Docker Desktop"')
        end
      end
    end
  end
end
