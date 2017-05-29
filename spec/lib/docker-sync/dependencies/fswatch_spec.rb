require 'spec_helper'

RSpec.describe DockerSync::Dependencies::Fswatch do
  it_behaves_like 'a dependency'
  it_behaves_like 'a binary-checking dependency', 'fswatch'
  it_behaves_like 'a binary-installing dependency', 'fswatch'
end
