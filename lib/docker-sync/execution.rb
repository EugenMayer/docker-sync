require 'open3'
require 'thor/shell'

module Execution

  Thread.abort_on_exception = true

  def exec(command, prefix, color)
    Open3.popen3(command) do |_, stdout, stderr, _|

      # noinspection RubyAssignmentExpressionInConditionalInspection
      while line_out = stdout.gets
        say_status prefix, line_out, color
      end

      # noinspection RubyAssignmentExpressionInConditionalInspection
      while line_err = stderr.gets
        say_status prefix, line_err, :red
      end

    end
  end

  def threadexec(command, prefix = nil, color = nil)

    if prefix.nil?
      # TODO: probably pick the command name without args
      prefix = 'unknown'
    end

    if color.nil?
      color = :cyan
    end

    Thread.new {
     exec(command, prefix, color)
    }

  end

  def forkexec(command, prefix = nil, color = nil)

    if prefix.nil?
      # TODO: probably pick the command name without args
      prefix = 'unknown'
    end

    if color.nil?
      color = :cyan
    end

    Process.fork do
      exec(command, prefix, color)
    end

  end

end