require 'spec_helper'

# TODO: the unox part should only be called if it is MacOS - its only needed then
RSpec.describe DockerSync::Dependencies::Unison do
  before do
    allow(DockerSync::Dependencies::PackageManager).to receive(:install_package)
    allow(DockerSync::Dependencies::Unox).to receive(:ensure!)
  end

  it_behaves_like 'a dependency'
  it_behaves_like 'a binary-checking dependency', 'unison'
  it_behaves_like 'a binary-installing dependency', 'unison'

  describe '.ensure!' do
    before do
      allow(described_class).to receive(:available?).and_return(available?)
    end

    subject { described_class.ensure! }

    context 'when unison is available' do
      let(:available?) { true }

    end

    context 'when unison is not available' do
      let(:available?) { false }
    end
  end
end
