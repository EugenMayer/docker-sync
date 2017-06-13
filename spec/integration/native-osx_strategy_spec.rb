require 'spec_helper'
require 'fileutils'

RSpec.describe 'native_osx strategy', command_execution: :allowed do
  include Rspec::Bash

  let(:env)                  { create_stubbed_env }
  let(:bin)                  { File.expand_path(File.join(__dir__, '..', '..', 'bin', 'docker-sync')) }
  let(:config_file_template) { File.expand_path(File.join(__dir__, '..', '..', 'spec', 'fixtures', 'native_osx', 'docker-sync.yml')) }
  let(:config_file_path)     { File.join(env.dir, 'docker-sync.yml') }
  let(:host_app_template)    { 'spec/fixtures/app_skeleton' }
  let(:host_app_path)        { File.join(env.dir, File.basename(host_app_template)) }
  let(:test_env_vars)        { { 'DOCKER_SYNC_SKIP_UPGRADE' => 'true', 'DOCKER_SYNC_SKIP_UPDATE' => 'true', 'DOCKER_SYNC_SKIP_DEPENDENCIES_CHECK' => 'true' } }

  describe 'start' do
    around(:each) do |example|
      FileUtils.cp_r([host_app_template, config_file_template], env.dir)
      FileUtils.chdir(env.dir) do
        replace_in_file(config_file_path, '{{HOST_APP_PATH}}', "'#{host_app_path}'")
        env.execute_inline("#{bin} start", test_env_vars)
        sleep 1 # because, you know ¯\_(ツ)_/¯
        example.run
        env.execute_inline("#{bin} clean", test_env_vars)
      end
    end

    it 'creates a PID file' do
      expect(File.file?('.docker-sync/daemon.pid')).to be true
    end

    it 'creates a log file' do
      expect(File.file?('.docker-sync/daemon.log')).to be true
    end

    it_behaves_like 'a synchronized directory', '/host_sync'
    it_behaves_like 'a synchronized directory', '/app_sync'
  end
end
