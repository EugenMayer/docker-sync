module DockerSync
  module Dependencies
    module PackageManager
      class Pkg < Base
        PKG_NOT_AVAILABLE = 'PKG is not installed. Please install it and try again.'.freeze

        def self.available?
          return @available if defined? @available
          @available = find_executable0('pkg')
        end

        def self.ensure!
          raise(PKG_NOT_AVAILABLE) unless available?
        end

        private

        def install_cmd
          "pkg install -y #{package}"
        end
      end
    end
  end
end
