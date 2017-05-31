target_test 'probably old template config' do |config|
  if config[:config_templates] && config[:config_templates].class == Array
    next {
      severity: :warning,
      message: 'config probably contains obsolete configuration field.' +
        ' Use "templates:" instead of "config_templates:" in Fulmar 2'
    }
  end
end

target_test 'probably missing plugin' do |config|
  if config[:mariadb] && !config.plugins.include?(:mariadb)
    next {
      severity: :warning,
      message: 'config contains a mariadb config but plugin is not loaded'
    }
  end
end

target_test 'probably old mariadb config' do |config|
  if config[:maria]
    next {
      severity: :warning,
      message: 'config contains a config setting "maria" which is "mariadb" in Fulmar 2'
    }
  end
end
