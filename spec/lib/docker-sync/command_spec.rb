require 'spec_helper'
require 'docker-sync/command'

RSpec.describe DockerSync::Command do
  # actual subprocess invocations are mocked out.
  describe '.run' do
    let(:pid) { 123 }
    %i[master slave reader writer].each do |fd|
      let(fd) { double(fd, close: true) }
    end

    before do
      # Use fake PTY to avoid MacOS resource exhaustion
      allow(PTY).to receive(:open).and_return([master, slave])
      allow(IO).to receive(:pipe).and_return([reader, writer])
      allow(described_class).to receive(:spawn).and_return(pid)
    end

    it 'spawns with new pwd with :dir option' do
      expect(described_class).to receive(:spawn).with('ls', hash_including(chdir: '/tmp/banana'))
      described_class.run('ls', dir: '/tmp/banana')
    end

    it 'spawns with PWD without :dir option' do
      expect(described_class).to receive(:spawn).with('ls', hash_including(chdir: Dir.pwd))
      described_class.run('ls')
    end

    it 'works when interactive' do
      expect(PTY).to receive(:open).twice
      expect(IO).to receive(:pipe).once
      expect(described_class).to receive(:spawn)
      cmd = described_class.run('ls')
      expect(cmd.pid).to eq pid
    end
  end
end
