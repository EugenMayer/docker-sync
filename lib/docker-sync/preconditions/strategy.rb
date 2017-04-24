require 'docker-sync/preconditions/preconditions_osx'
require 'docker-sync/preconditions/preconditions_linux'

require 'singleton'
require 'os'

module DockerSync
  module Preconditions
    class Strategy
      include Singleton

      attr_accessor :strategy

      def initialize
        if DockerSync::Preconditions::Strategy.is_osx
          @strategy = DockerSync::Preconditions::Osx.new
        elsif DockerSync::Preconditions::Strategy.is_linux
          @strategy = DockerSync::Preconditions::Linux.new
        end
      end

      def self.is_osx
        return OS.mac?
      end

      def self.is_linux
        return OS.linux?
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
    end
  end
end

