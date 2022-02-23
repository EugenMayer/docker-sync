require 'spec_helper'
require 'docker-sync/docker_compose_session'
require 'docker-sync/command'

RSpec.describe DockerSync::DockerComposeSession do
  let(:exitstatus) { 0 }
  let(:status) { double('exit status', to_s: "pid 12345 exit #{exitstatus}", to_i: exitstatus) }
  let(:output) { 'exit output' }
  let(:command) do
    double('command',
           status: status,
           captured_output: output,
           captured_error: '')
  end

  before do
    allow(status).to receive(:success?).and_return(exitstatus == 0)
    allow(DockerSync::Command).to receive(:run).and_return(command)
    allow(command).to receive(:join).and_return(command)
  end

  describe '.new' do
    it 'allows file override' do
      session = DockerSync::DockerComposeSession.new(files: ['foo.yml'])
      expect(DockerSync::Command).to receive(:run).with('docker-compose', '--file=foo.yml', 'up', dir: nil)
      session.up
    end

    it 'allows more files override' do
      session = DockerSync::DockerComposeSession.new(files: ['foo.yml', 'bar.yml', 'buz.yml'])
      expect(DockerSync::Command).to receive(:run).with('docker-compose',
                                                        '--file=foo.yml',
                                                        '--file=bar.yml',
                                                        '--file=buz.yml',
                                                        'up',
                                                        dir: nil)
      session.up
    end

    it 'allows file and directory override' do
      session = DockerSync::DockerComposeSession.new(files: ['foo.yml'], dir: './tmp')
      expect(DockerSync::Command).to receive(:run).with('docker-compose', '--file=foo.yml', 'up', dir: './tmp')
      session.up
    end
  end

  describe '#up' do
    it 'runs containers without build option' do
      session = DockerSync::DockerComposeSession.new
      expect(DockerSync::Command).to receive(:run).with('docker-compose', 'up', dir: nil)
      session.up
    end

    it 'runs containers with build option' do
      session = DockerSync::DockerComposeSession.new
      expect(DockerSync::Command).to receive(:run).with('docker-compose', 'up', '--build', dir: nil)
      session.up(build: true)
    end

    it 'returns captured output' do
      session = DockerSync::DockerComposeSession.new
      result = session.up
      expect(result).to eq 'exit output'
    end
  end

  describe '#down' do
    it 'brings down containers' do
      session = DockerSync::DockerComposeSession.new
      expect(DockerSync::Command).to receive(:run).with('docker-compose', 'down', dir: nil)
      session.down
    end

    it 'brings down containers with files: and dir: options' do
      session = DockerSync::DockerComposeSession.new(files: ['foo.yml'], dir: './tmp')
      expect(DockerSync::Command).to receive(:run).with('docker-compose', '--file=foo.yml', 'down', dir: './tmp')
      session.down
    end
  end

  describe '#stop' do
    it 'stops containers' do
      session = DockerSync::DockerComposeSession.new
      expect(DockerSync::Command).to receive(:run).with('docker-compose', 'stop', dir: nil)
      session.stop
    end

    it 'stops containers with files: and dir: options' do
      session = DockerSync::DockerComposeSession.new(files: ['foo.yml'], dir: './tmp')
      expect(DockerSync::Command).to receive(:run).with('docker-compose', '--file=foo.yml', 'stop', dir: './tmp')
      session.stop
    end
  end
end
