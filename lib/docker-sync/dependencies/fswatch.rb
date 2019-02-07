module DockerSync
  module Dependencies
    module Fswatch
      UNSUPPORTED = 'Fswatch is not expected to run on platforms other then MacOS'

      def self.available?
        forbid! unless Environment.mac?
        return @available if defined? @available
        @available = find_executable0('fswatch')
      end

      def self.ensure!
        return if available?

        PackageManager.install_package('fswatch')
        puts "please restart docker sync so the installation of fswatch takes effect"
        exit(1)
      end

      def self.forbid!
        raise UNSUPPORTED
      end
    end
  end
end
