require 'yaml'
require 'dotenv'

module DockerSync
  module ConfigSerializer
    class << self
      # @param [String] config_path path to the yaml configuration to load
      # @return [Object] returns a Yaml hashmap, expaneded by ENV vars
      def default_deserializer_file(config_path)
        config_string = File.read(config_path)
        default_deserializer_string(config_string)
      end

      # @param [String] config_string the configuration string inf yaml format
      # @return [Object] a yaml hashmap
      def default_deserializer_string(config_string)
        deserialize_config( expand_env_variables(config_string) )
      end

      private

      # Replaces our tokens, in this case all ENV variables we defined. Find those in the string an replace
      # them with then values from our ENV, including the dotenv file
      # @param [String] config_string
      # @return [String]
      def expand_env_variables(config_string)
        load_dotenv

        env_hash = {}
        ENV.each {|k,v| env_hash[k.to_sym] = v }
        config_string.gsub!('${', '%{')
        config_string % env_hash
      end


      # deserializes the configuration string, right now as a yaml formatted string
      # @param [String] config_string
      # @return [Object]
      def deserialize_config(config_string)
        # noinspection RubyResolve
        YAML.load(config_string)
      end

      # Loads the dotenv file but also lets us overide the source not being .env but anything you put
      # into the ENV variable DOCKER_SYNC_ENV_FILE
      # @return [Object]
      def load_dotenv
        # TODO: ensure we do this once only
        env_file = ENV.fetch('DOCKER_SYNC_ENV_FILE', '.env')

        # noinspection RubyResolve
        Dotenv.load(env_file)
      end
    end
  end
end
