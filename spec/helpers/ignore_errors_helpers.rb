module IgnoreErrorsHelpers
  def ignore_errors(*errors)
    yield
  rescue *errors => ex
    puts "warning: #{ex.class} ignored"
  end
end

RSpec.configuration.include(IgnoreErrorsHelpers)
