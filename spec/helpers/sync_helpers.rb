RSpec::Matchers.define :be_in_sync_with do |container_dir|
  attr_reader :actual, :expected, :container_name, :container_dir, :host_dir

  attr_accessor :container_name_missing_error
  container_name_missing_error = 'Container name is missing. Please chain `.in_container(container_name)` to define it.'.freeze

  match do |host_dir|
    @container_dir = container_dir
    @host_dir      = host_dir
    raise container_name_missing_error if container_name.nil? || container_name.empty?
    @actual,   host_stderr,      _status = env.execute_inline("cd #{host_dir}; find . -type f -print0 | sort -z | xargs -0 shasum -a 256")
    @expected, container_stderr, _status = env.execute_inline("docker exec #{container_name} bash -c 'cd #{container_dir}; find . -type f -print0 | sort -z | xargs -0 sha256sum'")
    raise host_stderr      unless host_stderr.empty?
    raise container_stderr unless container_stderr.empty?
    expected == actual
  end

  chain :in_container do |container_name|
    @container_name = container_name
  end

  diffable
  def diff_source
    "`#{host_dir}` filetree on host"
  end
  def diff_target
    "`#{container_dir}` filetree in container `#{container_name}`"
  end
  description { "synchronize #{diff_target} with #{diff_source}." }
  failure_message { "Expected #{diff_target} to match #{diff_source}." }
  failure_message_when_negated { "Expected #{diff_target} to be different than #{diff_source}." }
end
