require 'open3'
require 'colorize'

module Execution

  Thread.abort_on_exception = true

  def threadexec(command, prefix = nil, color = nil)

    unless prefix.nil?
      prefix = "#{prefix}    | "
    end

    if color.nil?
      color = :cyan
    end

    Thread.new {
      Open3.popen3(command) do |stdin, stdout, stderr, wait_thr|

        while lineOut = stdout.gets
          puts prefix.nil? ? lineOut : prefix.colorize(color) + lineOut
        end

        while lineErr = stderr.gets
          puts prefix.nil? ? lineErr : prefix.colorize(color) + lineErr
        end

      end
    }

  end

end