module DockerSync
  module Dependencies
    module Rsync
      def self.available?
        find_executable0('rsync')
      end

      def self.ensure!
        PackageManager.install_package('rsync') unless available?
      end
    end
  end
end
