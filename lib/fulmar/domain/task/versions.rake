include Fulmar::Domain::Service::CommonHelperService

namespace :versions do
  task :load_config do
    # load the configuration from the config gem
  end

  @versioned_servers = full_configuration[:environments].select { |_name, config| config[:type].to_s == 'rsync_with_versions' }

  desc 'List existing versions on the server'
  task :list do
    if @versioned_servers.empty?
      puts 'None of the configured environments supports versioning.'
    else
      puts 'Environments which support versioning:'
      @versioned_servers.each_key do |env|
        puts "- #{env}"
      end

      puts "\nSo run one of these now:"
      @versioned_servers.each_key do |env|
        puts "$ fulmar versions:list:#{env}"
      end
    end
  end

  unless @versioned_servers.empty?
    namespace :list do
      @versioned_servers.each_key do |env|
        desc "List available versions for environment \"#{env}\""
        task env do
          environment = env
          file_sync.list_releases(false).each { |item| puts item }
        end
      end
    end
  end
end
