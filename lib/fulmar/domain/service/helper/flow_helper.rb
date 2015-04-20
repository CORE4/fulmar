require 'fulmar/infrastructure/service/flow_service'

module Fulmar
  module Domain
    module Service
      module Helper
        # Provides access helper to the flow service from within a task
        module FlowHelper
          def flow
            storage['flow'] ||= Fulmar::Infrastructure::Service::FlowService.new remote_shell, configuration
          end
        end
      end
    end
  end
end
