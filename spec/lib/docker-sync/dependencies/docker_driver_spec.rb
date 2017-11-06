require 'spec_helper'

RSpec.describe DockerSync::Dependencies::Docker::Driver do
  describe '.docker_for_mac?' do
    let(:mac?) { true }

    before do
      allow(DockerSync::Environment).to receive(:mac?).and_return(mac?)
      allow(described_class).to receive(:system).and_return(true)
      described_class.remove_instance_variable(:@docker_for_mac) if described_class.instance_variable_defined? :@docker_for_mac
    end

    subject { described_class.docker_for_mac? }

    context 'when not running on a Macintosh' do
      let(:mac?) { false }
      it { is_expected.to be false }
      it { is_expected.to execute_nothing }
    end

    it 'checks if Docker is running in Hyperkit' do
      subject
      expect(described_class).to have_received(:system).with('pgrep -q com.docker.osx.hyperkit.linux')
    end

    it 'is memoized' do
      expect { 1.times { described_class.docker_for_mac? } }.to change { described_class.instance_variable_defined?(:@docker_for_mac) }
      expect(described_class).to have_received(:system).exactly(:once)
    end
  end

  describe '.docker_toolbox?' do
    let(:mac?)                      { true }
    let(:docker_machine_available?) { true }

    before do
      allow(DockerSync::Environment).to receive(:mac?).and_return(mac?)
      allow(described_class).to receive(:find_executable0).with('docker-machine').and_return(docker_machine_available?)
      allow(described_class).to receive(:system).and_return(true)
      described_class.remove_instance_variable(:@docker_toolbox) if described_class.instance_variable_defined? :@docker_toolbox
    end

    subject { described_class.docker_toolbox? }

    context 'when not running on a Macintosh' do
      let(:mac?) { false }
      it { is_expected.to be false }
      it { is_expected.to execute_nothing }
    end

    context 'when docker-machine is not available' do
      let(:docker_machine_available?) { false }
      it { is_expected.to be false }
      it { is_expected.to execute_nothing }
    end

    it 'checks if Docker is running in Boot2Docker' do
      subject
      expect(described_class).to have_received(:system).with('docker info | grep -q "Operating System: Boot2Docker"')
    end

    it 'is memoized' do
      expect { 2.times { described_class.docker_toolbox? } }.to change { described_class.instance_variable_defined?(:@docker_toolbox) }
      expect(described_class).to have_received(:system).exactly(:once)
    end
  end
end
