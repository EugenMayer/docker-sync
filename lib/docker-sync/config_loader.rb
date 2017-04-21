require 'pathname'
require 'dotenv'
require 'yaml'

module DockerSync
  module ConfigLoader
    class << self
      def load_config(config_path)
        return unless File.exist?(config_path)

        load_dotenv

        config_string = File.read(config_path)
        interpolate_config_string(config_string)
      end

      def interpolate_config_string(config_string)
        env_hash = {}
        ENV.each {|k,v| env_hash[k.to_sym] = v }
        config_string.gsub!('${', '%{')
        config_string = config_string % env_hash
        YAML.load(config_string)
      end

      private

        def load_dotenv
          env_file = ENV.fetch('DOCKER_SYNC_ENV_FILE', '.env')

          Dotenv.load(env_file)
        end

    end
  end
end
