module DockerSync
  module Preconditions
    class Linux
      def check_all_preconditions(config)
      end

      def docker_available
      end

      def docker_running
      end

      def fswatch_available
      end

      def rsync_available
      end

      def unison_available
      end
    end

  end
end
