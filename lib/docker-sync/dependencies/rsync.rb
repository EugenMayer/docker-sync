module DockerSync
  module Dependencies
    module Rsync
      def self.available?
        return @available if defined? @available
        @available = find_executable0('rsync')
      end

      def self.ensure!
        PackageManager.install_package('rsync') unless available?
      end
    end
  end
end
