# Move this file into the plugin

target_test 'mariadb is loaded' do |config|
  if config[:type] == :mariadb && !config.plugins.include?(:mariadb)
    next {
      severity: :warning,
      message: 'config uses mysql/mariadb but your config is missing the maria plugin'
    }
  end
end

target_test 'database name exists' do |config|
  if config.plugins.include?(:mariadb) && config[:maria] && config[:maria][:database].blank?
    next {
      severity: :error,
      message: 'config is missing a database name in maria:database'
    }
  end
end