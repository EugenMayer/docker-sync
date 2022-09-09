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
      defined?(Bundler) ? Bundler.unbundled_system(cmd) : Kernel.system(cmd)
    end

    def self.default_ignores()
      ['.docker-sync/daemon.log', '.docker-sync/daemon.pid']
    end
  end
end
