require 'open3'
require 'thor/shell'

module Execution
  Thread.abort_on_exception = true

  def thread_exec(command, prefix = 'unknown', color = :cyan)
    Thread.new do
      Open3.popen3(command) do |_, stdout, stderr, _|
        # noinspection RubyAssignmentExpressionInConditionalInspection
        while line_out = stdout.gets
          say_status with_time(prefix), line_out, color
        end

        # noinspection RubyAssignmentExpressionInConditionalInspection
        while line_err = stderr.gets
          say_status with_time(prefix), line_err, :red
        end
      end
    end
  end

  # unison doesn't work when ran in a new thread
  # this functions creates a full new process instead
  def fork_exec(command, _prefix = 'unknown', _color = :cyan)
    Process.fork  { `#{command}` || raise(command + ' failed') }
  end

  def with_time(prefix)
    "[#{Time.now}] #{prefix}"
  end
end
