require 'open3'
require 'thor/shell'

module Execution

  Thread.abort_on_exception = true

  def threadexec(command, prefix = nil, color = nil)

    if prefix.nil?
      # TODO: probably pick the command name without args
      prefix = 'unknown'
    end

    if color.nil?
      color = :cyan
    end

    Thread.new {
      Open3.popen3(command) do |stdin, stdout, stderr, wait_thr|

        while lineOut = stdout.gets
          say_status prefix, lineOut, color
        end

        while lineErr = stderr.gets
          say_status prefix, lineErr, :red
        end

      end
    }

  end

end