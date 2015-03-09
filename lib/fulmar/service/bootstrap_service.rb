module Fulmar
  module Service
    class BootstrapService

      def initialize
        $logger = Fulmar::Service::LoggerService.new(STDOUT)
      end

      def fly
        #$config = Fulmar::Domain::Service::ConfigurationService.new
        Fulmar::Domain::Service::ApplicationService.new.run
      end
    end
  end
end