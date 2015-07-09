db_configs = []
configuration.each do |env, target, data|
  db_configs << [env, target] if data[:type] == 'maria'
end

# Expects two hashes as parameters each with { :environment, :target, :name } set
# :name is either environment:target or just the environment, if the is only one target
def create_update_task(from, to)
  namespace to[:name] do
    task "from_#{from[:name]}" do
      configuration.environment = from[:environment]
      configuration.target = from[:target]
      puts 'Getting dump...'
      sql_dump = database.download_dump
      if sql_dump == ''
        puts 'Cannot create sql dump'
      else
        configuration.environment = to[:environment]
        configuration.target = to[:target]
        puts 'Sending dump...'
        remote_sql_dump = upload(sql_dump)
        database.load_dump(remote_sql_dump)
      end
    end
  end
end

def name(env, target, counts)
  counts[env] > 1 ? "#{env}:#{target}" : env
end

def create_update_tasks(db_configs)
  counts = {}
  db_configs.each do |config|
    counts[config.first] = 0 unless counts[config.first]
    counts[config.first] += 1
  end

  namespace :update do
    db_configs.each do |from_db|
      db_configs.each do |to_db|
        next if from_db == to_db # no need to sync a database to itself
        next if from_db.last != to_db.last # sync only matching target names
        from = {
          environment: from_db.first,
          target: from_db.last,
          name: name(from_db.first, from_db.last, counts)
        }
        to = {
          environment: to_db.first,
          target: to_db.last,
          name: name(to_db.first, to_db.last, counts)
        }
        create_update_task(from, to)
      end
    end
  end
end

if configuration.feature?(:database) && db_configs.any?
  namespace :database do
    create_update_tasks(db_configs) if db_configs.count > 1
  end
end
