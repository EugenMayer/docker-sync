module DockerSync
  module Dependencies
    module PackageManager
      class << self
        extend Forwardable
        def_delegators :package_manager, :available?, :ensure!, :install_package
      end

      def self.package_manager
        return @package_manager if defined? @package_manager
        return @package_manager = PackageManager::Brew if PackageManager::Brew.available?
        return @package_manager = PackageManager::Apt  if PackageManager::Apt.available?
        return @package_manager = PackageManager::Yum  if PackageManager::Yum.available?
        @package_manager = PackageManager::None
      end
    end
  end
end
