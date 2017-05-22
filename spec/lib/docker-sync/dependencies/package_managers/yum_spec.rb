require 'spec_helper'

RSpec.describe DockerSync::Dependencies::PackageManager::Yum do
  it_behaves_like 'a dependency'
  it_behaves_like 'a binary-checking dependency', 'yum'
  it_behaves_like 'a package manager'
end
