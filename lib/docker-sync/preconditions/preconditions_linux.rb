module DockerSync
  module Preconditions
    class Linux
      def check_all_preconditions(config)
        return unless should_run_precondition?

        docker_available
        docker_running

        if config.unison_required?
          unison_available
        end

        if config.rsync_required?
          rsync_available
          fswatch_available
        end
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

      def is_driver_docker_for_mac?
        return false
      end

      def is_driver_docker_toolbox?
        return false
      end
      private

      def should_run_precondition?(silent: false)
        true
      end


    end
  end
end
