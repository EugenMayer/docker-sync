require 'spec_helper'

RSpec.describe 'native_osx strategy', command_execution: :allowed do
  include Rspec::Bash

  let(:env)           { create_stubbed_env }
  let(:config_switch) { '--config=spec/fixtures/native_osx/docker-sync.yml' }
  let(:test_env_vars) { { 'DOCKER_SYNC_SKIP_UPGRADE' => 'true', 'DOCKER_SYNC_SKIP_UPDATE' => 'true', 'DOCKER_SYNC_SKIP_DEPENDENCIES_CHECK' => 'true' } }

  describe 'start' do
    around(:each) do |example|
      env.execute_inline('rm -rf .docker-sync')
      env.execute_inline("bin/docker-sync start #{config_switch}", test_env_vars)
      sleep 1 # because, you know ¯\_(ツ)_/¯
      example.run
      env.execute_inline("bin/docker-sync clean #{config_switch}", test_env_vars)
      env.execute_inline('rm -rf .docker-sync')
    end

    it 'creates a PID file' do
      expect(File.file?('.docker-sync/daemon.pid')).to be true
    end

    it { expect('spec/fixtures/app').to be_in_sync_with('/host_sync').in_container('docker_sync_specs-sync') }
    it { expect('spec/fixtures/app').to be_in_sync_with('/app_sync').in_container('docker_sync_specs-sync') }
  end
end
