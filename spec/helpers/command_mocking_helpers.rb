class CommandExecutionNotAllowed < ::StandardError
  COMMAND_EXECUTORS = %i(system exec spawn `).freeze

  attr_reader :method_name, :args
  def initialize(method_name, *args)
    @method_name = method_name
    @args        = args
  end

  def to_s
    "Command execution is not allowed. Please stub the following call: #{method_name}(#{args.map(&:inspect).join(', ')})"
  end
end

RSpec.configure do |config|
  config.before(:each) do
    CommandExecutionNotAllowed::COMMAND_EXECUTORS.each do |command_executor|
      allow_any_instance_of(Object).to receive(command_executor).and_wrap_original do |method, *args|
        raise CommandExecutionNotAllowed.new(method.name, *args)
      end
      allow(Kernel).to receive(command_executor).and_wrap_original do |method, *args|
        raise CommandExecutionNotAllowed.new(method.name, *args)
      end
    end
  end
end

RSpec::Matchers.define :execute_nothing do |_expected|
  match do |_actual|
    CommandExecutionNotAllowed::COMMAND_EXECUTORS.each do |command_executor|
      expect(Kernel).to_not receive(command_executor)
    end
  end
end
