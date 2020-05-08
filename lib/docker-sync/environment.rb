require 'os'

module DockerSync
  module Environment
    def self.linux?
      return @linux if defined? @linux
      @linux = OS.linux?
    end

    def self.mac?
      return @mac if defined? @mac
      @mac = OS.mac?
    end

    def self.freebsd?
      @freebsd ||= OS.freebsd?
    end

    def self.system(cmd)
      defined?(Bundler) ? Bundler.clean_system(cmd) : Kernel.system(cmd)
    end

    def self.compose_file
      if ENV['COMPOSE_FILE']
        ENV['COMPOSE_FILE'].split(/[:;]/)
      else
        ["docker-compose.yml"]
      end
    end
  end
end
