target_test 'local path exists' do |config|
  if config[:local_path] && !File.exist?(config[:local_path])
    next {
      severity: :warning,
      message: "#{config.environment}:#{config.target} has no valid local_path (#{config[:local_path]})"
    }
  end
end

target_test 'remote_path is set' do |config|
  types = %w(rsync rsync_with_version)
  if types.include?(config[:type]) && config[:remote_path].blank?
    next {severity: :error, message: 'config is missing a remote path for rsync'}
  end
end
