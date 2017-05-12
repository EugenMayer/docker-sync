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
    end
  end
end
