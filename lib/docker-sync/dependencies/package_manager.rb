require 'forwardable'

module DockerSync
  module Dependencies
    module PackageManager
      class << self
        extend Forwardable
        def_delegators :package_manager, :available?, :ensure!, :install_package
      end

      def self.package_manager
        return @package_manager if defined? @package_manager
        supported_package_managers.each do |package_manager|
          return @package_manager = package_manager if package_manager.available?
        end
        @package_manager = PackageManager::None
      end

      def self.supported_package_managers
        ObjectSpace.each_object(::Class).select { |klass| klass < self::Base && klass != self::None }
      end
    end
  end
end
