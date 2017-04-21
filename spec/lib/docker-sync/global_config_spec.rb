require 'securerandom'
require 'tmpdir'

describe DockerSync::GlobalConfig do
  let(:global_config_path) { Pathname.new(Dir.tmpdir).join("#{SecureRandom.hex}.yml") }

  before do
    stub_const('DockerSync::GlobalConfig::CONFIG_PATH', global_config_path)
  end

  subject {
    Singleton.__init__(DockerSync::GlobalConfig)
    described_class.load
  }

  describe '#load' do
    it 'initialize with default value if global config file is missing' do
      delete_global_config

      expect(subject.to_h).to eql(DockerSync::GlobalConfig::DEFAULTS)
    end

    it 'load existing configuration if global config file is found' do
      config = { "foo" => "bar" }
      stub_global_config(config)

      expect(subject.to_h).to eql(config)
    end
  end

  describe '#first_run?' do
    it 'return true if global config file is missing' do
      delete_global_config

      is_expected.to be_first_run
    end

    it 'load existing configuration if global config file is found' do
      stub_global_config

      is_expected.not_to be_first_run
    end
  end

  describe '#update!' do
    it 'allows updating global config' do
      config = { "foo" => "bar" }
      stub_global_config(config)

      subject.update! "baz" => 'bazmaru'

      updated_config = DockerSync::ConfigLoader.load_config(global_config_path)
      expect(updated_config).to eql("foo" => "bar", "baz" => "bazmaru")
    end
  end

  def delete_global_config
    File.delete(global_config_path) if File.exist?(global_config_path)
  end

  def stub_global_config(config = {})
    File.open(global_config_path, 'w') {|f| f.write config.to_yaml }
  end
end
