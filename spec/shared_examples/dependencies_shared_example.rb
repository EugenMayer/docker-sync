RSpec.shared_examples 'a dependency' do
  before do
    described_class.remove_instance_variable(:@available) if described_class.instance_variable_defined? :@available
  end

  it 'implements `.available?`' do
    expect(described_class).to respond_to :available?
  end

  it 'implements `.ensure!`' do
    expect(described_class).to respond_to :ensure!
  end
end

RSpec.shared_examples 'a binary-checking dependency' do |binary|
  describe '.available?' do
    let(:binary_exists?) { true }

    before do
      described_class.remove_instance_variable(:@available) if described_class.instance_variable_defined? :@available
      allow(described_class).to receive(:find_executable0).with(binary).and_return(binary_exists?)
    end

    subject { described_class.available? }

    context "when `#{binary}` binary is found in $PATH" do
      it { is_expected.to be true }
    end

    context "when `#{binary}` binary is not found in $PATH" do
      let(:binary_exists?) { false }
      it { is_expected.to be false }
    end
  end
end

RSpec.shared_examples 'a binary-installing dependency' do |binary|
  describe '.ensure!' do
    let(:available?) { true }

    before do
      allow(described_class).to receive(:available?).and_return(available?)
      allow(DockerSync::Dependencies::PackageManager).to receive(:install_package)
    end

    subject { described_class.ensure! }

    context "when `#{binary}` is available" do
      it { is_expected_not_to_raise_error }
    end

    context "when `#{binary}` is not available" do
      let(:available?) { false }

      it 'tries to install it' do
        subject
        expect(DockerSync::Dependencies::PackageManager).to have_received(:install_package).with(binary)
      end
    end
  end
end
