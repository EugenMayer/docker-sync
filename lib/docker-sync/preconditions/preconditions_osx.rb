require 'mkmf'

module DockerSync
  module Preconditions
    class Osx
      def check_all_preconditions(config)
        Dependencies::PackageManager.ensure!
        Dependencies::Docker.ensure!

        if config.unison_required?
          Dependencies::Unison.ensure!
        end

        if config.rsync_required?
          Dependencies::Rsync.ensure!
          Dependencies::Fswatch.ensure!
        end
      end
    end
  end
end
