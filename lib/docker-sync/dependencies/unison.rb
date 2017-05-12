module DockerSync
  module Dependencies
    module Unison
      def self.available?
        return @available if defined? @available
        @available = find_executable0('unison')
      end

      def self.ensure!
        PackageManager.install_package('unison') unless available?
        Unox.ensure!
      end
    end
  end
end
