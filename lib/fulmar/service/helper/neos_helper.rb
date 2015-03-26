require 'fulmar/infrastructure/service/neos_service'

module Fulmar
  module Domain
    module Service
      module Helper
        module NeosHelper
          def neos
            storage['neos'] ||= Fulmar::Infrastructure::Service::NeosService.new remote_shell, configuration
          end
        end
      end
    end
  end
end
