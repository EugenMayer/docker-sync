RSpec::Matchers.define :be_in_sync_with do |container_dir|
  attr_reader :actual, :expected, :container_dir, :host_dir

  def container_dir_matches_host_dir?
    @actual,   host_stderr,      _status = env.execute_inline("cd #{host_dir}; find . -type f -print0 | sort -z | xargs -0 shasum -a 256")
    @expected, container_stderr, _status = env.execute_inline("docker exec #{container_name} bash -c 'cd #{container_dir}; find . -type f -print0 | sort -z | xargs -0 sha256sum'")
    raise host_stderr      unless host_stderr.empty?
    raise container_stderr unless container_stderr.empty?
    expected == actual
  end

  match do |host_dir|
    @container_dir = container_dir
    @host_dir      = host_dir
    @start_time    = Time.now

    while Time.now < @start_time + delay
      if container_dir_matches_host_dir?
        # puts "Yay: #{diff_target} matches #{diff_source} in #{(Time.now - @start_time).round(3).seconds.inspect} instead of #{delay.inspect}."
        break true
      end
      sleep 0.25.second
    end
  end

  chain :in_container do |container_name|
    @container_name = container_name
  end

  chain :within do |delay|
    @delay = delay
  end

  chain :immediately do
    @delay = 0.second
  end

  def container_name
    @container_name.presence || raise('Container name is missing. Please chain `.in_container(container_name)` to define it.'.freeze)
  end

  def delay
    @delay ||= 1.second
  end

  diffable
  description { "synchronize #{diff_target} with #{diff_source} within #{delay.inspect}." }
  failure_message { "Expected #{diff_target} to match #{diff_source} within #{delay.inspect}." }
  failure_message_when_negated { "Expected #{diff_target} to be different than #{diff_source} within #{delay.inspect}." }

  def diff_source
    "`#{host_dir}` filetree on host"
  end

  def diff_target
    "`#{container_dir}` filetree in container `#{container_name}`"
  end
end
