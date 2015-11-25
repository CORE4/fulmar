
module Fulmar
  module Domain
    module Service
      module Helper
        # Provides access helper to the database service from within a task
        module DatabaseHelper
          def database
            storage['database'] ||= Fulmar::Infrastructure::Service::Database::DatabaseService.new configuration
          end
        end
      end
    end
  end
end