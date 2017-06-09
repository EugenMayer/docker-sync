RSpec::Matchers.define :be_in_sync_with do |container_dir|
  match do |host_dir|
    raise "Container name is missing. Please chain `.in_container(container_name)` to define it." if @container_name.nil? || @container_name.empty?
    shasums, _stderr, _status = env.execute_inline("cd #{host_dir}; find . -type f -exec shasum -a 256 {} \\;")
    _stdout, _stderr, status  = env.execute_inline("docker exec #{@container_name} bash -c 'cd #{container_dir}; echo -n \"#{shasums}\" | sha256sum -c -'")
    status.success?
  end

  chain :in_container do |container_name|
    @container_name = container_name
  end
end
