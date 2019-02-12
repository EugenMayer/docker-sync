module CommandExecutionMock
  COMMAND_EXECUTORS = %i(system exec exit spawn `).freeze

  def self.included(_base)
    define_custom_matchers
    disallow_command_execution
  end

  def define_custom_matchers
    RSpec::Matchers.define :execute_nothing do
      match do
        COMMAND_EXECUTORS.each do |command_executor|
          expect(Kernel).to_not receive(command_executor)
        end
      end
    end
  end

  def disallow_command_execution
    print "Adding RSpec hook to stub command execution... "
    RSpec.configuration.before(:each) do |example|
      unless example.metadata[:command_execution].to_s == 'allowed'
        COMMAND_EXECUTORS.each do |executor|
          stub_command_executor(executor)
        end
      end
    end
    puts "OK"
  end

  def stub_command_executor(executor)
    allow_any_instance_of(Object).to receive(executor).and_wrap_original do |method, *args|
      raise CommandExecutionNotAllowed.new(method.name, *args)
    end
    allow(Kernel).to receive(executor).and_wrap_original do |method, *args|
      raise CommandExecutionNotAllowed.new(method.name, *args)
    end
  end

  class CommandExecutionNotAllowed < ::StandardError
    attr_reader :method_name, :args
    def initialize(method_name, *args)
      @method_name = method_name
      @args        = args
    end

    def to_s
      "Command execution is not allowed. Please stub the following call: #{method_name}(#{args.map(&:inspect).join(', ')})"
    end
  end
end

RSpec.configure do
  include CommandExecutionMock
end
