require 'pathname'

module DockerForMacConfigCheck
  D4M_MOUNTS_FILE       = File.expand_path('~/Library/Containers/com.docker.docker/Data/database/com.docker.driver.amd64-linux/mounts').freeze
  WARNING_SIGN          = "\033[0;33mWARNING\033[0m ".freeze
  ANSI_COLOR_CHAR_REGEX = /\033\[(\d{1,3}(;\d{1,3})?)?m/

  def self.included(_base)
    return unless File.exist?(D4M_MOUNTS_FILE)
    File.readlines(D4M_MOUNTS_FILE).each do |mount_line|
      mount_src, _mount_dst = mount_line.split(':')
      Pathname.new(Dir.tmpdir).ascend do |parent_dir|
        return if File.realpath(parent_dir) == File.realpath(mount_src)
      end
    end
    big_warning(<<-EOS)
      The OS temporary directory (#{File.realpath(Dir.tmpdir)}) does not seem to be shared with Hyperkit VM.
      The integration tests will likely fail (or at least, behave unexpectedly).
      Please go to Docker -> Preferences -> File Sharing tab and add it (or a parent directory).
    EOS
  end

  def self.tmpdir_toplevel_dir
    @tmpdir_toplevel_dir ||= Dir.tmpdir.gsub(/(\/[^\/]+).*/, '\\1')
  end

  def self.big_warning(message)
    message.gsub!(/(^\s*|\s*$)/, '')
    message_length = message.lines.max_by(&:length).length
    warning_length = WARNING_SIGN.gsub(ANSI_COLOR_CHAR_REGEX, '').length
    total_length   = warning_length * (message_length / warning_length + 1)
    puts "#{WARNING_SIGN}#{WARNING_SIGN * (total_length / warning_length)}#{WARNING_SIGN}"
    message.each_line do |line|
      puts "#{WARNING_SIGN}#{line.strip.center(total_length)}#{WARNING_SIGN}"
    end
    puts "#{WARNING_SIGN}#{WARNING_SIGN * (total_length / warning_length)}#{WARNING_SIGN}"
  end
end

RSpec.configure do |config|
  include DockerForMacConfigCheck
end
