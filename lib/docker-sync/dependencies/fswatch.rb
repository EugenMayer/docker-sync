module DockerSync
  module Dependencies
    module Fswatch
      def self.available?
        raise 'Fswatch cannot be available for other platforms then MacOS' unless Environment.mac?
        return @available if defined? @available
        @available = find_executable0('fswatch')
      end

      def self.ensure!
        return if available?

        PackageManager.install_package('fswatch')
        puts "please restart docker sync so the installation of fswatch takes effect"
        exit(1)
    end
    end
  end
end
