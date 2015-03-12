namespace :versions do

  task :load_config do
    # load the configuration from the config gem
  end

  desc 'List existing versions on the server'
  task :list do
    # FIXME: Replace this with the actual config
    @environments = {
        environments: {
            staging: { host: 'kallisto', remote_path: '/srv/asft', releases_path: 'releases', type: 'rsync_with_versions' },
            preview: { host: 'themisto', remote_path: '/srv/asft', releases_path: 'releases', type: 'rsync' }
        }
    }

    versioned_servers = @environments.select{|name, config| config[:type].to_s == 'rsync_with_versions' }

    if versioned_servers.empty?
      puts 'None of the configured environments supports versioning.'
    else
      puts 'Environments which support versioning:'
      versioned_servers.each do |env, config|
        puts "- #{env}"
      end
    end

  end

end