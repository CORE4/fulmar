module Fulmar
  module Service
    # Initializes the rake service and starts it
    class BootstrapService
      def initialize
        $logger = Fulmar::Service::LoggerService.new(STDOUT)
      end

      def fly
        Fulmar::Domain::Service::ApplicationService.new.run
      end
    end
  end
end
