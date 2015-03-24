require 'fulmar/domain/service/configuration_service'

module Fulmar
  module Domain
    module Service
      # Provides the helper methods used in the tasks
      module CommonHelperService
        attr_accessor :environment

        def full_configuration
          configuration.configuration
        end

        def configuration
          (@_config_service ||= Fulmar::Domain::Service::ConfigurationService.instance)
        end

        def composer(command, arguments = [])
          (@_composer ||= Fulmar::Infrastructure::Service::ComposerService.new).execute(command, arguments)
        end

        def local_shell
          fail 'You need to set an environment and a target first' unless configuration.ready?
          unless @_local_shell
            @_local_shell = {}
          end
          @_local_shell["#{configuration.environment}:#{configuration.target}"] ||= Fulmar::Infrastructure::Service::ShellService.new configuration[:local_path]
        end

        def remote_shell
          fail 'You need to set an environment and a target first' unless configuration.ready?
          unless @_remote_shell
            @_remote_shell = {}
          end
          @_remote_shell["#{configuration.environment}:#{configuration.target}"] ||= Fulmar::Infrastructure::Service::ShellService.new(configuration[:remote_path], configuration[:hostname])
        end

        def file_sync
          @_file_sync ||= Fulmar::FileSync.create_transfer configuration
        end

        def database
          @_database ||= Fulmar::Infrastructure::Service::Database::DatabaseService.new configuration
        end

        def render_templates
          (Fulmar::Domain::Service::ConfigRenderingService.new configuration).render
        end

        def git
          @_git ||= Fulmar::Infrastructure::Service::GitService.new configuration
        end
      end
    end
  end
end
