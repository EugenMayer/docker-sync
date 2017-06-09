require 'spec_helper'

RSpec.describe 'native_osx strategy', command_execution: :allowed do
  include Rspec::Bash

  let(:env)           { create_stubbed_env }
  let(:bin)           { 'bin/docker-sync' }
  let(:config_switch) { '--config=spec/fixtures/native_osx/docker-sync.yml' }
  let(:test_env_vars) { { 'DOCKER_SYNC_SKIP_UPGRADE' => 'true', 'DOCKER_SYNC_SKIP_UPDATE' => 'true', 'DOCKER_SYNC_SKIP_DEPENDENCIES_CHECK' => 'true' } }

  around(:each) do |example|
    env.execute_inline('rm -rf .docker-sync')
    example.run
    env.execute_inline("#{bin} stop #{config_switch}", test_env_vars)
    env.execute_inline("#{bin} clean #{config_switch}", test_env_vars)
    env.execute_inline('rm -rf .docker-sync')
  end

  subject { env.execute_inline("#{bin} start #{config_switch}", test_env_vars) }

  describe 'start' do
    it 'starts successfully' do
      _stdout, _stderr, status = subject
      expect(status).to be_success
    end

    it 'creates a PID file' do
      subject
      sleep 1 # because the PID file is created after fork
      expect(File.file?('.docker-sync/daemon.pid')).to be true
    end

    it 'syncs to /host_sync' do
      subject
      shasums, _stderr, _status = env.execute_inline('cd spec/fixtures/app/; find . -type f -exec shasum -a 256 {} \;')
      _stdout, _stderr, status  = env.execute_inline("docker exec app-sync bash -c 'cd /host_sync; echo -n \"#{shasums}\" | sha256sum -c -'")
      expect(status).to be_success
    end

    it 'syncs to /app_sync' do
      subject
      shasums, _stderr, _status = env.execute_inline('cd spec/fixtures/app/; find . -type f -exec shasum -a 256 {} \;')
      _stdout, _stderr, status  = env.execute_inline("docker exec app-sync bash -c 'cd /app_sync; echo -n \"#{shasums}\" | sha256sum -c -'")
      expect(status).to be_success
    end
  end
end
