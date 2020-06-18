module DockerSync
  module Dependencies
    module Unison
      def self.available?
        find_executable0('unison')
      end

      def self.ensure!
        PackageManager.install_package('unison') unless available?
      end
    end
  end
end
