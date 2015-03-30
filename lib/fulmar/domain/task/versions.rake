include Fulmar::Domain::Service::Helper::CommonHelper

namespace :versions do
  @versioned_servers = {}

  full_configuration[:environments].each_pair do |env, targets|
    next if env == :all

    targets.each_pair do |target, config|
      @versioned_servers["#{env}:#{target}"] = config if config[:type].to_s == 'rsync_with_versions'
    end
  end

  unless @versioned_servers.empty?
    namespace :list do
      @versioned_servers.each_key do |env|
        desc "List available versions for environment \"#{env}\""
        task env do
          configuration.environment = env.split(':').first
          configuration.target = env.split(':').last
          file_sync.list_releases(false).each { |item| puts item }
        end
      end
    end

    namespace :clean do
      @versioned_servers.each_key do |env|
        desc "Delete obsolete versions for target \"#{env}\""
        task env do
          configuration.environment = env.split(':').first
          configuration.target = env.split(':').last
          file_sync.cleanup
        end
      end
    end
  end
end
