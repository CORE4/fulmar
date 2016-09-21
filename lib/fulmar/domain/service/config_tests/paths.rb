test 'local path exists' do |config|
  if config[:local_path] && !File.exist?(config[:local_path])
    next :warning, "#{config.environment}:#{config.target} has no valid local_path (#{config[:local_path]})"
  end
end

test 'remote_path is set' do |config|
  types = [:rsync, :rsync_with_version]
  if types.include?(config[:type]) && config[:remote_path].blank?
    next :error, "#{env}:#{target} is missing a remote path"
  end
end
