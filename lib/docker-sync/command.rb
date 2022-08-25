begin
  require 'pty'
rescue LoadError
  # for Windows support, tolerate a missing PTY module
end

module DockerSync
  # based on `Backticks::Command` from `Backticks` gem
  class Command
    FOREVER = 86_400 * 365
    CHUNK = 1_024

    # @return [Integer] child process ID
    attr_reader :pid

    # @return [nil,Process::Status] result of command if it has ended; nil if still running
    attr_reader :status

    # @return [String] all input that has been captured so far
    attr_reader :captured_input

    # @return [String] all output that has been captured so far
    attr_reader :captured_output

    # @return [String] all output to stderr that has been captured so far
    attr_reader :captured_error

    # Run a command. The parameters are same as `Kernel#spawn`.
    #
    # Usage:
    #    run('docker-compose', '--file=joe.yml', 'up', '-d', 'mysvc')
    def self.run(*argv, dir: nil)
      nopty = !defined?(PTY)

      stdin_r, stdin = nopty ? IO.pipe : PTY.open
      stdout, stdout_w = nopty ? IO.pipe : PTY.open
      stderr, stderr_w = IO.pipe

      chdir = dir || Dir.pwd
      pid = spawn(*argv, in: stdin_r, out: stdout_w, err: stderr_w, chdir: chdir)

      stdin_r.close
      stdout_w.close
      stderr_w.close

      self.new(pid, stdin, stdout, stderr)
    end

    def initialize(pid, stdin, stdout, stderr)
      @pid = pid
      @stdin = stdin
      @stdout = stdout
      @stderr = stderr
      @status = nil

      @captured_input  = String.new(encoding: Encoding::BINARY)
      @captured_output = String.new(encoding: Encoding::BINARY)
      @captured_error  = String.new(encoding: Encoding::BINARY)
    end

    def success?
      status.success?
    end

    def join(limit = FOREVER)
      return self if @status

      tf = Time.now + limit
      until (t = Time.now) >= tf
        capture(tf - t)
        res = Process.waitpid(@pid, Process::WNOHANG)
        if res
          @status = $?
          return self
        end
      end

      nil
    end

    private

    def capture(limit)
      streams = [@stdout, @stderr]
      streams << STDIN if STDIN.tty?

      ready, = IO.select(streams, [], [], limit)

      # proxy STDIN to child's stdin
      if ready && ready.include?(STDIN)
        data = STDIN.readpartial(CHUNK) rescue nil
        if data
          @captured_input << data
          @stdin.write(data)
        else
          # our own STDIN got closed; proxy this fact to the child
          @stdin.close unless @stdin.closed?
        end
      end

      # capture child's stdout and maybe proxy to STDOUT
      if ready && ready.include?(@stdout)
        data = @stdout.readpartial(CHUNK) rescue nil
        if data
          @captured_output << data
          STDOUT.write(data)
          fresh_output = data
        end
      end

      # capture child's stderr and maybe proxy to STDERR
      if ready && ready.include?(@stderr)
        data = @stderr.readpartial(CHUNK) rescue nil
        if data
          @captured_error << data
          STDERR.write(data)
        end
      end
      fresh_output
    rescue Interrupt
      # Proxy Ctrl+C to the child
      Process.kill('INT', @pid) rescue nil
      raise
    end
  end
end
