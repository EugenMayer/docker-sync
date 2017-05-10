require 'spec_helper'

RSpec.describe 'Unison strategy' do
  include Rspec::Bash

  let(:bin) { 'bin/docker-sync' }
  let(:env) { create_stubbed_env }

  describe '--version' do
    subject { 'docker-sync --version' }

    it 'outputs the version' do
      stdout, _stderr, _status = env.execute_inline(subject)
      expect(stdout).to eq `cat VERSION`
    end

    it 'is successful' do
      _stdout, _stderr, status = env.execute_inline(subject)
      expect(status).to be_success
    end
  end

  describe 'start' do
    before do
      dir1_path = File.join(env.dir, 'dir1')
      Dir.mkdir(dir1_path)
      File.write(File.join(dir1_path, 'file1'), 'This is some content')
    end

    xit 'starts successfully' do
      # This won't work unless we stub all preconditions (brew, docker, etc..)
      # and/or we have a `--no-auto-install` option
      _stdout, _stderr, status = env.execute_inline('docker-sync start')
      expect(status).to be_success
    end
  end
end
