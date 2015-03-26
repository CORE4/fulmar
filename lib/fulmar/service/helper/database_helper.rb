module Fulmar
  module Domain
    module Service
      module Helper
        module DatabaseHelper
          def database
            storage['database'] ||= Fulmar::Infrastructure::Service::Database::DatabaseService.new configuration
          end
        end
      end
    end
  end
end
