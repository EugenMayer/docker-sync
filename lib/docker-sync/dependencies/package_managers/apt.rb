module DockerSync
  module Dependencies
    module PackageManager
      class Apt < Base
        APT_NOT_AVAILABLE = 'APT is not installed. Please install it and try again.'.freeze

        def self.available?
          return @available if defined? @available
          @available = find_executable0('apt-get')
        end

        def self.ensure!
          raise(APT_NOT_AVAILABLE) unless available?
        end

        private

        def install_cmd
          "apt-get install -y #{package}"
        end
      end
    end
  end
end
