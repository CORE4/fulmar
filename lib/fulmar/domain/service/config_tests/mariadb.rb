# Move this file into the plugin

test 'mariadb is loaded' do |config|
  if config[:type] == :mariadb && !config.plugins.include?(:mariadb)
    next :warning, "#{env}:#{target} uses mysql/mariadb but your config is missing the maria plugin"
  end
end

test 'database name exists' do |config|
  if config.plugins.include?(:mariadb) && config[:maria] && config[:maria][:database].blank?
    next :error, "#{env}:#{target} is missing a database name in maria:database"
  end
end