module RaiseErrorHelpers
  def is_expected_to_raise_error(*args)
    expect { subject }.to raise_error(*args)
  end

  def is_expected_not_to_raise_error
    expect { subject }.not_to raise_error
  end
  alias is_expected_to_not_raise_error is_expected_not_to_raise_error
end

RSpec.configuration.include(RaiseErrorHelpers)
