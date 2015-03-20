include Fulmar::Domain::Service::CommonHelperService

namespace :versions do

  task :load_config do
    # load the configuration from the config gem
  end

  @versioned_servers = {}
  full_configuration[:environments].each_pair do |env, targets|
    next if env == :all

    targets.each_pair do |target, config|
      @versioned_servers["#{env}:#{target}"] = config if config[:type].to_s == 'rsync_with_versions'
    end
  end

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
          configuration.environment = env.split(':').first
          configuration.target = env.split(':').last
          file_sync.list_releases(false).each{|item| puts item}
        end

      end

    end

  end

end
