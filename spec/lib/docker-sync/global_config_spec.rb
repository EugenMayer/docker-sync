require 'securerandom'
require 'tmpdir'
require 'docker-sync/config/global_config'

describe DockerSync::GlobalConfig do
  let(:faked_global_config_path) { Pathname.new(Dir.tmpdir).join("#{SecureRandom.hex}.yml") }

  before do
    DockerSync::ConfigLocator.global_config_path = faked_global_config_path
  end

  subject {
    Singleton.__init__(DockerSync::GlobalConfig)
    described_class.load
  }

  describe '#load' do
    it 'initialize with default values if global config file is missing' do
      delete_global_config

      expect(subject.to_h).to eql(DockerSync::GlobalConfig::DEFAULTS)
    end

    it 'load existing configuration if global config file is found' do
      config = {'foo' => 'bar'}
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

  describe '#update existing!' do
    it 'allows updating global config' do
      config = {'foo' => 'bar'}
      stub_global_config(config)

      subject.update! 'baz' => 'bazmaru'

      updated_config = DockerSync::GlobalConfig.load
      expect(updated_config.to_h).to eql('foo' => 'bar', 'baz' => 'bazmaru')
    end
  end


  describe '#update from default' do
    # we cannot put this into the upper update group since otherwise the modified config will be loaded
    # due to the singleton we have in DockerSync::GlobalConfig
    it 'allows updating from default configuration' do
      delete_global_config
      config = DockerSync::GlobalConfig.load
      config.update! 'new' => 'value'

      updated_config = DockerSync::GlobalConfig.load
      expect(updated_config.to_h).to include('new' => 'value')
    end
  end


  def delete_global_config
    File.delete(DockerSync::ConfigLocator.current_global_config_path) if File.exist?(DockerSync::ConfigLocator.current_global_config_path)
  end

  def stub_global_config(config = {})
    File.open(DockerSync::ConfigLocator.current_global_config_path, 'w') {|f| f.write config.to_yaml }
  end
end
