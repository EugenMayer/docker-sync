require 'docker-sync/preconditions/preconditions_osx'
require 'docker-sync/preconditions/preconditions_linux'

require 'singleton'

module DockerSync
  module Preconditions
    class Strategy
      include Singleton

      attr_accessor :strategy

      def initialize
        if Environment.mac?
          @strategy = DockerSync::Preconditions::Osx.new
        elsif Environment.linux?
          @strategy = DockerSync::Preconditions::Linux.new
        end
      end

      def check_all_preconditions(config)
        strategy.check_all_preconditions(config)
      end

      def docker_available
        strategy.docker_available
      end

      def docker_running
        strategy.docker_running
      end

      def rsync_available
        strategy.rsync_available
      end

      def fswatch_available
        strategy.fswatch_available
      end

      def unison_available
        strategy.unison_available
      end

      def is_driver_docker_for_mac?
        strategy.is_driver_docker_for_mac?
      end

      def is_driver_docker_toolbox?
        strategy.is_driver_docker_toolbox?
      end
    end
  end
end

