test 'hostname is set' do |config|
  warning = nil
  config.each do |env, target, data|
    if data[:hostname].blank? && !data[:host].blank?
      warning = [:warning, "#{env}:#{target} has a host (#{data[:host]}) but is missing a hostname"]
    end
  end
  next warning
end

test 'hostnames in ssh config' do |config|
  hostnames = ssh_hostnames
  info = nil
  config.each do |env, target, data|
    next if data[:hostname].blank?

    unless hostnames.include? data[:hostname]
      info = [:info, "#{env}:#{target} has a hostname (#{data[:hostname]}) which is not in your ssh config"]
    end
  end
  next info
end

test 'required hostnames' do |config|
  types = %i(rsync rsync_with_version maria)
  error = nil
  config.each do |env, target, data|
    if types.include?(data[:type]) && data[:hostname].blank?
      error = [:error, "#{env}:#{target} requires a hostname (#{data[:hostname]})"]
    end
  end
  next error
end
