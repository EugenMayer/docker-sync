require 'spec_helper'

# unox is only available/allowed for mac
RSpec.describe DockerSync::Dependencies::Unox do
  let(:available) { true }
  let(:mac?)   { true }

  before do
    allow(DockerSync::Environment).to receive(:system)
    allow(DockerSync::Environment).to receive(:system).with(/^brew list unox/).and_return(available)
    allow(DockerSync::Environment).to receive(:mac?).and_return(mac?)

    described_class.remove_instance_variable(:@available) if described_class.instance_variable_defined? :@available
  end

  it_behaves_like 'a dependency'

  describe '.available?' do
    subject { described_class.available? }

    context "when Unox was installed using brew" do
      let(:available) { true }

      it { is_expected.to be true }
    end

    context "when Unox was not installed using brew" do
      let(:available) { false }

      it { is_expected.to be false }
    end

    context 'when its not a mac' do
      let(:mac?) { false }

      it "unox should not be used - so raise" do
        expect{subject}.to raise_error()
      end
    end
  end

  describe '.ensure!' do
    subject { described_class.ensure! }

    context 'when it is already available' do
      it { is_expected_to_not_raise_error }
    end

    context 'when it is not available' do
      let(:available) { false }

      before do
        allow(DockerSync::Dependencies::PackageManager).to receive(:install_package)
      end

      it 'eventually cleans up any non-brew version installed' do
        expect(described_class).to receive(:cleanup_non_brew_version!)
        subject
      end

      it 'tries to install it' do
        subject
        expect(DockerSync::Dependencies::PackageManager).to have_received(:install_package).with('eugenmayer/dockersync/unox')
      end
    end

    context 'when its not a mac' do
      let(:mac?) { false }

      it "unox should not be used - so raise" do
        expect{subject}.to raise_error()
      end
    end
  end

  describe 'cleanup_non_brew_version!' do
    before do
      allow_any_instance_of(Thor::Shell::Color).to receive(:say_status)
    end

    subject { described_class.cleanup_non_brew_version! }

    context 'when a (legacy) non-brew version is not installed' do
      before { allow(described_class).to receive(:non_brew_version_installed?).and_return(false) }

      it 'does nothing' do
        subject
        expect(DockerSync::Environment).to_not have_received(:system)
      end
    end

    context 'when a (legacy) non-brew version is installed' do
      before { allow(described_class).to receive(:non_brew_version_installed?).and_return(true) }

      context 'when user confirms cleanup' do
        before { allow_any_instance_of(Thor::Shell::Color).to receive(:yes?).and_return(true) }

        it 'deletes the binary' do
          subject
          expect(DockerSync::Environment).to have_received(:system).with('sudo rm -f /usr/local/bin/unison-fsmonitor')
        end
      end

      context 'when user cancels cleanup' do
        before { allow_any_instance_of(Thor::Shell::Color).to receive(:yes?).and_return(false) }
        it { is_expected_to_raise_error RuntimeError }
      end
    end
  end

  describe '.non_brew_version_installed?' do
    subject { described_class.non_brew_version_installed? }

    context 'when brew version is available' do
      before { expect(described_class).to receive(:available?).and_return(true) }
      it { is_expected.to be false }
    end

    context 'when brew version is not available' do
      before { expect(described_class).to receive(:available?).and_return(false) }

      context 'when `/usr/local/bin/unison-fsmonitor` exists' do
        before { allow(File).to receive(:exist?).with('/usr/local/bin/unison-fsmonitor').and_return(true) }
        it { is_expected.to be true }
      end

      context 'when `/usr/local/bin/unison-fsmonitor` does not exist' do
        before { allow(File).to receive(:exist?).with('/usr/local/bin/unison-fsmonitor').and_return(false) }
        it { is_expected.to be false }
      end
    end
  end
end
