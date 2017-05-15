module DockerSync
  module Dependencies
    module Fswatch
      def self.available?
        return @available if defined? @available
        @available = find_executable0('fswatch')
      end

      def self.ensure!
        PackageManager.install_package('fswatch') unless available?
      end
    end
  end
end
