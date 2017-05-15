module DockerSync
  module Dependencies
    module PackageManager
      class Brew < Base
        BREW_NOT_AVAILABLE = 'Brew is not installed. Please install it (see https://brew.sh) and try again.'.freeze

        def self.available?
          return @available if defined? @available
          @available = find_executable0('brew')
        end

        def self.ensure!
          raise(BREW_NOT_AVAILABLE) unless available?
        end

        private

        def install_cmd
          "brew install #{package}"
        end
      end
    end
  end
end
