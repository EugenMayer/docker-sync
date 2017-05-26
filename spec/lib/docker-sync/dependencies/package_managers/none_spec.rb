require 'spec_helper'

RSpec.describe DockerSync::Dependencies::PackageManager::None do
  it_behaves_like 'a dependency'

  describe '.available?' do
    subject { described_class.available? }
    it { is_expected.to be true }
  end

  describe '.ensure!' do
    subject { described_class.ensure! }
    it { is_expected.to execute_nothing }
  end

  describe '.install_package(package_name)' do
    let(:package_name) { 'some-package' }

    before do
      allow(described_class).to receive(:ensure!)
      allow_any_instance_of(Thor::Shell::Color).to receive_messages(
        say_status: nil,
        yes?: true
      )
    end

    subject { described_class.install_package(package_name) }

    it 'tells user to install any of the supported package managers' do
      expect { subject }.to raise_error(described_class::NO_PACKAGE_MANAGER_AVAILABLE)
    end
  end
end
