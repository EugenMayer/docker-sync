module DockerSync
  module Dependencies
    module Fswatch
      def self.available?
        raise 'Fswatch cannot be available for other platforms then MacOS' unless Environment.mac?
        return @available if defined? @available
        @available = find_executable0('fswatch')
      end

      def self.ensure!
        raise 'Fswatch cannot be installed on other platforms then MacOS' unless Environment.mac?
        PackageManager.install_package('fswatch') unless available?
      end
    end
  end
end
