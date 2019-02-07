RSpec.shared_examples 'a package manager' do
  it 'defines the command used to install a package' do
    expect(described_class.private_instance_methods(false)).to include :install_cmd
  end

  describe '.install_package(package_name)' do
    let(:user_confirmed?) { true }
    let(:package_name)    { 'some-package' }

    before do
      allow(DockerSync::Environment).to receive(:system).and_return(true)
      allow(described_class).to receive(:ensure!)
      allow_any_instance_of(Thor::Shell::Color).to receive_messages(
        say_status: nil,
        yes?: user_confirmed?
      )
    end

    subject { described_class.install_package(package_name) }

    it 'ensures this package manager is available' do
      subject
      expect(described_class).to have_received(:ensure!)
    end

    it 'asks for user confirmation' do
      expect_any_instance_of(Thor::Shell::Color).to receive(:yes?)
      subject
    end

    context 'when user confirmed installation' do
      let(:user_confirmed?) { true }
      let(:install_command) { described_class.new(package_name).send(:install_cmd) }

      it 'executes the package installation command' do
        subject
        expect(DockerSync::Environment).to have_received(:system).with(install_command)
      end
    end

    context 'when user canceled installation' do
      let(:user_confirmed?) { false }
      it { is_expected_to_raise_error RuntimeError }
    end
  end
end
