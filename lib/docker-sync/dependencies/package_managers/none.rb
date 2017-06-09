module DockerSync
  module Dependencies
    module PackageManager
      class None < Base
        NO_PACKAGE_MANAGER_AVAILABLE = 'No package manager was found. Please either install one of those supported (brew, apt, rpm) or install all dependencies manually.'.freeze

        def self.available?
          @available ||= true
        end

        def self.ensure!
          # noop
        end

        private

        def install_cmd
          raise(NO_PACKAGE_MANAGER_AVAILABLE)
        end
      end
    end
  end
end
