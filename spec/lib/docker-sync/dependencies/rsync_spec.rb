require 'spec_helper'

RSpec.describe DockerSync::Dependencies::Rsync do
  it_behaves_like 'a dependency'
  it_behaves_like 'a binary-checking dependency', 'rsync'
  it_behaves_like 'a binary-installing dependency', 'rsync'
end
