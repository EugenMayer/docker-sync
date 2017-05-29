require 'spec_helper'

RSpec.describe DockerSync::Dependencies::PackageManager do
  describe '.package_manager' do
    before do
      described_class.remove_instance_variable :@package_manager if described_class.instance_variable_defined? :@package_manager
      described_class.supported_package_managers.each do |package_manager|
        allow(package_manager).to receive(:available?).and_return(false)
      end
    end

    subject { described_class.package_manager }

    context 'when a package manager is available' do
      let(:available_package_manager) { described_class.supported_package_managers.sample }
      before { allow(available_package_manager).to receive(:available?).and_return(true) }
      it { is_expected.to eq available_package_manager }
    end

    context 'when no package manager is available' do
      it { is_expected.to eq described_class::None }
    end

    it 'is memoized' do
      expect { subject }.to change { described_class.instance_variable_defined? :@package_manager }.from(false).to(true)
    end
  end

  describe '.supported_package_managers' do
    subject { described_class.supported_package_managers }

    it 'returns all supported package managers' do
      expect(subject).to match_array [
        DockerSync::Dependencies::PackageManager::Brew,
        DockerSync::Dependencies::PackageManager::Apt,
        DockerSync::Dependencies::PackageManager::Yum
      ]
    end
  end
end
