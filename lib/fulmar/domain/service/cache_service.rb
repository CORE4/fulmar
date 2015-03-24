require 'fulmar/infrastructure/service/cache/dummy_cache_service'
require 'fulmar/infrastructure/service/cache/neos_cache_service'
require 'fulmar/infrastructure/service/cache/symfony_cache_service'

module Fulmar
  module Domain
    module Service
      # Provides a common interface for all environment specific cache services
      class CacheService
        attr_reader :type, :cache

        def initialize(shell, config, type = :none)
          @type = type
          @cache = case type
                   when :neos
                     Fulmar::Infrastructure::Service::Cache::NeosCacheService.new(shell, config)
                   when :symfony
                     Fulmar::Infrastructure::Service::Cache::SymfonyCacheService.new(shell, config)
                   else
                     Fulmar::Infrastructure::Service::Cache::DummyCacheService.new(shell, config)
                   end
        end

        def method_missing(name, parameters)
          @cache.call(name, parameters)
        end
      end
    end
  end
end
