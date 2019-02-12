require 'spec_helper'

RSpec.describe DockerSync::Dependencies do
  let(:config) { double(:config, unison_required?: false, rsync_required?: false, fswatch_required?: false) }
  let(:linux?)   { false }
  let(:freebsd?) { false }
  let(:mac?)     { false }

  before do
    allow(DockerSync::Environment).to receive(:linux?).and_return(linux?)
    allow(DockerSync::Environment).to receive(:freebsd?).and_return(freebsd?)
    allow(DockerSync::Environment).to receive(:mac?).and_return(mac?)
  end

  describe '.ensure_all!(config)' do
    before do
      allow(described_class).to receive(:ensure_all_for_mac!)
      allow(described_class).to receive(:ensure_all_for_freebsd!)
      allow(described_class).to receive(:ensure_all_for_linux!)
    end

    subject { described_class.ensure_all!(config) }

    context 'when running on a Macintosh' do
      let(:mac?) { true }

      it 'delegates to `ensure_all_for_mac!` with given config' do
        subject
        expect(described_class).to have_received(:ensure_all_for_mac!).with(config)
      end
    end

    context 'when running on Linux' do
      let(:linux?) { true }

      it 'delegates to `ensure_all_for_linux!` with given config' do
        subject
        expect(described_class).to have_received(:ensure_all_for_linux!).with(config)
      end
    end

    context 'when running on FreeBSD' do
      let(:freebsd?) { true }

      it 'delegates to `ensure_all_for_freebsd!` with given config' do
        subject
        expect(described_class).to have_received(:ensure_all_for_freebsd!).with(config)
      end
    end

    context 'when running on another OS' do
      it 'raises an error' do
        expect { subject }.to raise_error(RuntimeError)
      end
    end
  end

  describe '.ensure_all_for_linux!(_config)' do
    let(:linux?) { true }

    before do
      allow(described_class::Docker).to receive(:ensure!)
    end

    subject { described_class.ensure_all_for_linux!(config) }

    it 'ensures that Docker is available' do
      subject
      expect(described_class::Docker).to have_received(:ensure!)
    end

    context "when FSWatch is required by given `config`" do
      before do
        allow(config).to receive(:fswatch_required?).and_return(true)
      end

      it 'is forbidden' do
        expect { subject }.to raise_error(DockerSync::Dependencies::Fswatch::UNSUPPORTED)
      end
    end
  end

  describe '.ensure_all_for_freebsd!(_config)' do
    let(:freebsd?) { true }

    before do
      allow(described_class::Docker).to receive(:ensure!)
    end

    subject { described_class.ensure_all_for_freebsd!(config) }

    it 'ensures that Docker is available' do
      subject
      expect(described_class::Docker).to have_received(:ensure!)
    end

    context "when FSWatch is required by given `config`" do
      before do
        allow(config).to receive(:fswatch_required?).and_return(true)
      end

      it 'is forbidden' do
        expect { subject }.to raise_error(DockerSync::Dependencies::Fswatch::UNSUPPORTED)
      end
    end
  end

  describe '.ensure_all_for_mac!(config)' do
    let(:mac?) { true }

    before do
      allow(described_class::PackageManager).to receive(:ensure!)
      allow(described_class::Docker).to receive(:ensure!)
    end

    subject { described_class.ensure_all_for_mac!(config) }

    it 'ensures that a package manager is available' do
      subject
      expect(described_class::PackageManager).to have_received(:ensure!)
    end

    it 'ensures that Docker is available' do
      subject
      expect(described_class::Docker).to have_received(:ensure!)
    end

    context "when Unison is required by given `config`" do
      before do
        allow(config).to receive(:unison_required?).and_return(true)
        allow(described_class::Unison).to receive(:ensure!)
      end

      it 'ensures that Unison is available' do
        subject
        expect(described_class::Unison).to have_received(:ensure!)
      end
    end

    context "when Rsync is required by given `config`" do
      before do
        allow(config).to receive(:rsync_required?).and_return(true)
        allow(described_class::Rsync).to receive(:ensure!)
      end

      it 'ensures that Rsync is available' do
        subject
        expect(described_class::Rsync).to have_received(:ensure!)
      end
    end

    context "when FSWatch is required by given `config`" do
      before do
        allow(config).to receive(:fswatch_required?).and_return(true)
        allow(described_class::Fswatch).to receive(:ensure!)
      end

      it 'ensures that FSWatch is available' do
        subject
        expect(described_class::Fswatch).to have_received(:ensure!)
      end
    end
  end
end
