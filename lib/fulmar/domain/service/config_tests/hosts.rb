target_test 'hostname is set' do |config|
  if config[:hostname].blank? && !config[:host].blank?
    next {
      severity: :warning,
      message: "config has a host (#{[:host]}) but is missing a hostname"
    }
  end
end

target_test 'hostnames in ssh config' do |config|
  next if config[:hostname].blank?

  unless ssh_hostnames.include? config[:hostname]
    {severity: :info, message: "config has a hostname (#{config[:hostname]}) which is not in your ssh config"}
  end
end

target_test 'required hostnames' do |config|
  types = %i(rsync rsync_with_version maria)
  if types.include?(config[:type]) && config[:hostname].blank?
    next {severity: :error, message: "config requires a hostname (#{config[:hostname]})"}
  end
end
