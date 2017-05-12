module DockerSync
  module Dependencies
    module PackageManager
      NO_SUPPORTED_PACKAGE_MANAGER = 'No package manager available for your OS. Please file an issue on https://github.com/eugenmayer/docker-sync/issues mentioning your OS and favourite package manager.'.freeze

      class << self
        extend Forwardable
        def_delegators :package_manager, :available?, :ensure!, :install_package
      end

      def self.package_manager
        return @package_manager if defined? @package_manager
        return @package_manager = PackageManager::Brew if Environment.mac?
        raise(NO_SUPPORTED_PACKAGE_MANAGER)
      end
    end
  end
end
