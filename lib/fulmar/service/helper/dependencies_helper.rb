require 'fulmar/domain/service/dependency_service'

module Fulmar
  module Domain
    module Service
      module Helper
        # Provides access helper to the database service from within a task
        module DependenciesHelper
          def dependencies
            storage['dependecies'] ||= Fulmar::Domain::Service::DependencyService.new configuration
          end
        end
      end
    end
  end
end
