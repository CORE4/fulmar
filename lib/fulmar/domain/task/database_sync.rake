require 'pp'

db_configs = []
full_configuration[:environments].each_key do |env|
  next if env == :all
  full_configuration[:environments][env].each_pair do |target, data|
    if data[:type] == 'maria'
      db_configs << [env, target]
    end
  end
end

def create_update_task(from_db, to_db)
  namespace to_db.first do
    desc 'Update staging database with live data'
    task "from_#{from_db.first}" do
      configuration.environment = from_db.first
      configuration.target = from_db.last
      puts 'Getting dump...'
      sql_dump = database.download_dump
      if sql_dump == ''
        puts 'Cannot create sql dump'
      else
        configuration.environment = to_db.first
        configuration.target = to_db.last
        puts 'Sending dump...'
        remote_sql_dump = upload(sql_dump)
        database.load_dump(remote_sql_dump)
      end
    end
  end
end

def create_update_tasks(db_configs)
  namespace :update do
    db_configs.each do |from_db|
      db_configs.each do |to_db|
        next if from_db == to_db
        create_update_task(from_db, to_db)
      end
    end
  end
end

if db_configs.any?
  namespace :database do
    if db_configs.count > 1
      create_update_tasks(db_configs)
    end
  end
end
