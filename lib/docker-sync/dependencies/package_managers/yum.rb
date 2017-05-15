module DockerSync
  module Dependencies
    module PackageManager
      class Yum < Base
        YUM_NOT_AVAILABLE = 'Yum is not installed. Please install it and try again.'.freeze

        def self.available?
          return @available if defined? @available
          @available = find_executable0('yum')
        end

        def self.ensure!
          raise(YUM_NOT_AVAILABLE) unless available?
        end

        private

        def install_cmd
          "yum install -y #{package}"
        end
      end
    end
  end
end
