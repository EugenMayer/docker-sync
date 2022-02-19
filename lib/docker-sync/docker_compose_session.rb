module DockerSync
  # based on `Docker::Compose::Compose` from `docker-compose` gem
  class DockerComposeSession
    def initialize(dir:, file:)
      @shell = CommandRunner.new(dir: dir)
      @dir = dir
      @file = file # Array[String]
      @last_command = nil
    end

    def up(build: false)
      args = []
      args << '--build' if build

      run!('up', *args)
    end

    def stop
      run!('stop')
    end

    def down
      run!('down')
    end

    private

    def run!(*args)
      # file_args and args should be Array of String
      file_args = @file.map { |filepath| "--file=#{filepath}" }

      @last_command = @shell.run('docker-compose', *file_args, *args).join
      status = @last_command.status
      out = @last_command.captured_output
      err = @last_command.captured_error
      unless status.success?
        desc = (out + err).strip.lines.first || '(no output)'
        message = format("'%s' failed with status %s: %s", args.first, status.to_s, desc)
        raise message
      end

      out
    end
  end
end
