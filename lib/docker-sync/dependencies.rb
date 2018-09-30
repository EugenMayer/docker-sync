require 'mkmf'
require 'thor/shell'

Dir[
  File.join(__dir__, 'dependencies', 'package_managers', 'base.rb'),
  File.join(__dir__, 'dependencies', '**', '*.rb')
].each { |f| require f }

module DockerSync
  module Dependencies
    UNSUPPORTED_OPERATING_SYSTEM = 'Unsupported operating system. Are you sure you need DockerSync?'.freeze

    def self.ensure_all!(config)
      return if ENV['DOCKER_SYNC_SKIP_DEPENDENCIES_CHECK']
      return ensure_all_for_mac!(config)   if Environment.mac?
      return ensure_all_for_linux!(config) if Environment.linux?
      return ensure_all_for_freebsd!(config) if Environment.freebsd?
      raise(UNSUPPORTED_OPERATING_SYSTEM)
    end

    def self.ensure_all_for_mac!(config)
      PackageManager.ensure!
      Docker.ensure!
      Unison.ensure!  if config.unison_required?
      Rsync.ensure!   if config.rsync_required?
      if config.fswatch_required?
        unless Fswatch.available?
          Fswatch.ensure!
          puts "please restart docker sync so the installation of fswatch takes effect"
          exit 1
        end
      end

    end

    def self.ensure_all_for_linux!(_config)
      Docker.ensure!
    end

    def self.ensure_all_for_freebsd!(config)
      Docker.ensure!
      Unison.ensure!  if config.unison_required?
      Rsync.ensure!   if config.rsync_required?
    end
  end
end
