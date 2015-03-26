# This helper file provides tasks to set the environment. This is just for convenience
# so that these tasks might be a dependency for other tasks

namespace :environment do

  full_configuration[:environments].each_key do |env|
    # Sets the environment to #{env}
    task env do
      configuration.environment = env
    end

    namespace env do
      full_configuration[:environments][env].each_key do |target|
        # Sets the environment to #{env} and the target to #{target}
        task target do
          configuration.environment = env
          configuration.target = target
        end
      end
    end
  end
end
