require 'spec_helper'

RSpec.describe DockerSync::Dependencies::PackageManager::Apt do
  it_behaves_like 'a dependency'
  it_behaves_like 'a binary-checking dependency', 'apt-get'
  it_behaves_like 'a package manager'
end
