require 'spec_helper'
require 'pry'

RSpec.describe DockerSync::Dependencies::Docker do
  it_behaves_like 'a dependency'
  it_behaves_like 'a binary-checking dependency', 'docker'

  describe '.running?' do
    before do
      described_class.remove_instance_variable(:@running) if described_class.instance_variable_defined? :@running
    end

    subject { described_class.running? }

    context 'when `docker ps` succeeds' do
      before { expect(described_class).to receive(:system).with(/^docker ps/).and_return(true) }
      it { is_expected.to be true }
    end

    context 'when `docker ps` errors' do
      before { expect(described_class).to receive(:system).with(/^docker ps/).and_return(false) }
      it { is_expected.to be false }
    end
  end

  describe 'ensure!' do
    let(:available?) { true }
    let(:running?)   { true }

    before do
      allow(described_class).to receive(:available?).and_return(available?)
      allow(described_class).to receive(:running?).and_return(running?)
    end

    subject { described_class.ensure! }

    context 'when Docker is both available and running' do
      it { is_expected_not_to_raise_error }
    end

    context 'when Docker is not available' do
      let(:available?) { false }
      it { is_expected_to_raise_error RuntimeError }
    end

    context 'when Docker is not running' do
      let(:running?) { false }
      it { is_expected_to_raise_error RuntimeError }
    end
  end
end
