# This helper file provides tasks to set the environment. This is just for convenience
# so that these tasks might be a dependency for other tasks

namespace :environment do
  config.each do |env, target, _data|
    namespace env do
      # Sets the environment to #{env} and the target to #{target}
      task target do
        config.environment = env
        config.target = target
      end
    end
  end
end
