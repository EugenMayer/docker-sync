module FixtureHelpers
  def fixture_path(name)
    File.expand_path File.join(__dir__, '..', 'fixtures', name)
  end

  def use_fixture(name)
    Dir.chdir fixture_path(name) do
      yield
    end
  end
end

RSpec.configuration.include(FixtureHelpers)
