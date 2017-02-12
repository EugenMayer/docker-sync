require "yaml"
require 'dotenv'

module ConfigTemplate
  def self.interpolate_config_file(config_path)
      env_hash = {}
      ENV.each {|k,v| env_hash[k.to_sym] = v }
      # assuming the checks that file exist have already been performed
      config_string = File.read(config_path)
      config_string.gsub!('${', '%{')
      config_string = config_string % env_hash
      return YAML.load(config_string)
  end
end
