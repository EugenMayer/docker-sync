begin
  require 'pty'
rescue LoadError
  # for Windows support, tolerate a missing PTY module
end

module DockerSync
  # based on `Backticks::Runner` from `Backticks` gem
  class CommandRunner
    # Create an instance of Runner.
    def initialize(dir: nil)
      @dir = dir
    end

    # Run a command. The parameters are for `Kernel#spawn`.
    #
    # @return [Command] the running command
    #
    # @example Run docker-compose with complex parameters
    #   run('docker-compose', '--file=joe.yml', 'up', '-d', 'mysvc')
    def run(*argv)
      nopty = !defined?(PTY)

      stdin_r, stdin = nopty ? IO.pipe : PTY.open
      stdout, stdout_w = nopty ? IO.pipe : PTY.open
      stderr, stderr_w = IO.pipe

      dir = @dir || Dir.pwd
      pid = spawn(*argv, in: stdin_r, out: stdout_w, err: stderr_w, chdir: dir)

      stdin_r.close
      stdout_w.close
      stderr_w.close

      Command.new(pid, stdin, stdout, stderr)
    end
  end
end
