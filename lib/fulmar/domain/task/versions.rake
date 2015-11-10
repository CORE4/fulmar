include Fulmar::Domain::Service::Helper::CommonHelper

namespace :versions do
  @versioned_servers = {}

  configuration.each do |env, target, config|
    @versioned_servers["#{env}:#{target}"] = config if config[:type].to_s == 'rsync_with_versions'
  end

  unless @versioned_servers.empty?

    @versioned_servers.each_key do |env|
      target_count = @versioned_servers.keys.reduce(0) { |a, e| e.split(':').first == env.split(':').first ? a + 1 : a }

      task_environment = (target_count > 1 ? env : env.split(':').first)

      namespace :list do
        # Count of there are multiple targets within the environment
        # if not, we can omit the target name in the task and shorten it a bit
        # This should apply for almost all cases.

        desc "List available versions for environment/target \"#{env}\""
        task task_environment do
          configuration.environment = env.split(':').first
          configuration.target = env.split(':').last
          file_sync.list_releases(false).each { |item| puts item }
        end
      end

      namespace :clean do
        desc "Delete obsolete versions for target \"#{env}\""
        task task_environment do
          configuration.environment = env.split(':').first
          configuration.target = env.split(':').last
          file_sync.cleanup
        end
      end

      namespace :revert do
        desc "Revert to the previous version for \"#{env}\""
        task task_environment do
          configuration.environment = env.split(':').first
          configuration.target = env.split(':').last
          error 'Cannot revert to previous version.' unless file_sync.revert
        end
      end
    end
  end
end
