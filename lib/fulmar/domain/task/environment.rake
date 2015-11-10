# This helper file provides tasks to set the environment. This is just for convenience
# so that these tasks might be a dependency for other tasks

namespace :environment do
  configuration.each do |env, target, _data|
    namespace env do
      # Sets the environment to #{env} and the target to #{target}
      task target do
        configuration.environment = env
        configuration.target = target
      end
    end
  end
end
