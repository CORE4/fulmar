module Fulmar
  module Service
    # Initializes the rake service and starts it
    class BootstrapService
      def fly
        Fulmar::Domain::Service::ApplicationService.new.run
      end
    end
  end
end
