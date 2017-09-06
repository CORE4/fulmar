relevant_options = %i[rsync local_path remote_path host hostname shared templates ssh_config type]
relevant_options.each do |option|
  target_test "empty configuration settings #{option}" do |config|
    if config.key?(option) && config[option].nil?
      next {
        severity: :warning,
        message: "config setting '#{option}' is set to nil/null, this might overwrite default settings"
      }
    end
  end
end

target_test 'test if at least one shared directory exists' do |config|
  if config[:type] == 'rsync_with_versions' && (config[:shared].nil? || config[:shared].empty?)
    next {
      severity: warning,
      message: 'config does not contain a shared directory for versioning'
    }
  end
end
