require 'spec_helper'

RSpec.describe DockerSync::Dependencies::Docker::Driver do
  describe '.docker_on_mac?' do
    let(:mac?) { true }

    before do
      allow(DockerSync::Environment).to receive(:system).with('docker info | grep -q "Operating System: Docker Desktop"').and_return(false)
      allow(DockerSync::Environment).to receive(:system).with('pgrep -q com.docker.hyperkit').and_return(true)
      allow(DockerSync::Environment).to receive(:mac?).and_return(mac?)

      described_class.remove_instance_variable(:@docker_on_mac) if described_class.instance_variable_defined? :@docker_on_mac
    end

    subject { described_class.docker_on_mac? }

    context 'when not running on a Macintosh' do
      let(:mac?) { false }
      it { is_expected.to be false }
      it { is_expected.to execute_nothing }
    end

    it 'checks if Docker is running in Hyperkit' do
      subject

      expect(DockerSync::Environment).to have_received(:system).with('pgrep -q com.docker.hyperkit')
    end

    it 'checks if Docker is running in Virtualization' do
      allow(DockerSync::Environment).to receive(:system).with('pgrep -q com.docker.hyperkit').and_return(false)
      allow(DockerSync::Environment).to receive(:system).with('pgrep -q com.docker.virtualization').and_return(true)

      is_expected.to be true
      expect(DockerSync::Environment).to have_received(:system).with('pgrep -q com.docker.hyperkit')
      expect(DockerSync::Environment).to have_received(:system).with('pgrep -q com.docker.virtualization')
    end

    it 'checks if Docker is running in Docker Desktop' do
      allow(DockerSync::Environment).to receive(:system).with('docker info | grep -q "Operating System: Docker Desktop"').and_return(true)

      is_expected.to be true
      expect(DockerSync::Environment).to have_received(:system).with('docker info | grep -q "Operating System: Docker Desktop"')
    end

    it 'is memoized' do
      expect { 1.times { described_class.docker_on_mac? } }.to change { described_class.instance_variable_defined?(:@docker_on_mac) }

      expect(DockerSync::Environment).to have_received(:system).at_most(:twice)
    end
  end

  describe '.docker_toolbox?' do
    let(:mac?)                      { true }
    let(:docker_machine_available?) { true }

    before do
      allow(DockerSync::Environment).to receive(:mac?).and_return(mac?)
      allow(DockerSync::Environment).to receive(:system).and_return(true)
      allow(described_class).to receive(:find_executable0).with('docker-machine').and_return(docker_machine_available?)

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
      expect(DockerSync::Environment).to have_received(:system).with('docker info | grep -q "Operating System: Boot2Docker"')
    end

    it 'is memoized' do
      expect { 2.times { described_class.docker_toolbox? } }.to change { described_class.instance_variable_defined?(:@docker_toolbox) }
      expect(DockerSync::Environment).to have_received(:system).exactly(:once)
    end
  end
end
