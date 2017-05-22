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
    let(:user_confirmed?) { true }
    let(:package_name)    { 'some-package' }

    before do
      allow(described_class).to receive(:ensure!)
      allow_any_instance_of(Thor::Shell::Color).to receive_messages(
        say_status: nil,
        yes?: user_confirmed?
      )
    end

    subject { described_class.install_package(package_name) }

    it 'asks for user confirmation' do
      expect_any_instance_of(Thor::Shell::Color).to receive(:yes?)
      ignore_errors(RuntimeError) { subject }
    end

    context 'when user confirmed installation' do
      let(:user_confirmed?) { true }
      it { is_expected_to_raise_error RuntimeError }
    end

    context 'when user canceled installation' do
      let(:user_confirmed?) { false }
      it { is_expected_to_raise_error RuntimeError }
    end

  end
end
