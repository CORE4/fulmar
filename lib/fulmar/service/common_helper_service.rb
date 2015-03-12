require 'fulmar/domain/service/configuration_service'

module Fulmar

  module Domain

    module Service

      module CommonHelperService

        def use_environment(name)
          @environment = name
        end

        def full_configuration
          (@config_service ||= Fulmar::Domain::Service::ConfigurationService.new).configuration
        end

        def configuration
          (@config_service ||= Fulmar::Domain::Service::ConfigurationService.new).environment(@environment)
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

      end

    end

  end

end