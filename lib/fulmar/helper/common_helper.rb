require 'fulmar/domain/service/configuration_service'

module Fulmar

  module Helper

    def configuration
      @config_service ||= Fulmar::Domain::Service::ConfigurationService.new
    end
    
  end

end