require 'spec_helper'

RSpec.describe DockerSync::Dependencies::PackageManager::Brew do
  it_behaves_like 'a dependency'
  it_behaves_like 'a binary-checking dependency', 'brew'
  it_behaves_like 'a package manager'
end
