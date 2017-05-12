module DockerSync
  module Preconditions
    class Linux
      def check_all_preconditions(_config)
        Dependencies::Docker.ensure!
      end
    end
  end
end
