require 'fulmar/domain/service/configuration_service'

module Fulmar
  module Domain
    module Service
      # Provides the helper methods used in the tasks
      module CommonHelperService
        attr_accessor :environment

        def full_configuration
          (@config_service ||= Fulmar::Domain::Service::ConfigurationService.instance).configuration
        end

        def configuration
          (@config_service ||= Fulmar::Domain::Service::ConfigurationService.instance)
        end

        def composer(command, arguments = [])
          (@composer ||= Fulmar::Infrastructure::Service::ComposerService.new).execute(command, arguments)
        end

        def local_shell
          @local_shell ||= Fulmar::Infrastructure::Service::ShellService.new configuration[:local_path]
        end

        def remote_shell
          @remote_shell ||= Fulmar::Infrastructure::Service::ShellService.new configuration[:remote_path], configuration[:host]
        end

        def file_sync
          @file_sync ||= Fulmar::FileSync.create_transfer configuration
        end

        def database
          @_database ||= Fulmar::Infrastructure::Service::Database::DatabaseService.new configuration
        end

        def render_templates
          (Fulmar::Domain::Service::ConfigRenderingService.new configuration).render
        end
      end
    end
  end
end
