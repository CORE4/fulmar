require 'fulmar/domain/service/configuration_service'

module Fulmar

  module Domain

    module Service

      module CommonHelperService

        def configuration
          @config_service ||= Fulmar::Domain::Service::ConfigurationService.new
        end

        def composer(command, arguments = [])
          (@composer ||= Fulmar::Infrastructure::Service::ComposerService.new).execute(command, arguments)
        end

      end

    end

  end

end