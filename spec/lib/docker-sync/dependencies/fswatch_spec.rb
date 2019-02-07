require 'spec_helper'

RSpec.describe DockerSync::Dependencies::Fswatch do
  before do
    allow(DockerSync::Environment).to receive(:mac?).and_return(true)
    allow(described_class).to receive(:exit)
  end

  it_behaves_like 'a dependency'
  it_behaves_like 'a binary-checking dependency', 'fswatch'
  it_behaves_like 'a binary-installing dependency', 'fswatch'
end
