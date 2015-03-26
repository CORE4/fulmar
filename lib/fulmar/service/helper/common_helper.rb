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
          (storage['composer'] ||= Fulmar::Infrastructure::Service::ComposerService.new).execute(command, arguments)
        end

        def local_shell
          storage['local_shell'] ||= new_shell(configuration[:local_path])
        end

        def remote_shell
          storage['remote_shell'] ||= new_shell(configuration[:remote_path], configuration[:hostname])
        end

        def file_sync
          storage['file_sync'] ||= Fulmar::FileSync.create_transfer configuration
        end

        def database
          storage['database'] ||= Fulmar::Infrastructure::Service::Database::DatabaseService.new configuration
        end

        def render_templates
          (Fulmar::Domain::Service::ConfigRenderingService.new configuration).render
        end

        def git
          storage['git'] ||= Fulmar::Infrastructure::Service::GitService.new configuration
        end

        def upload(filename)
          Fulmar::Infrastructure::Service::CopyService.upload(local_shell, filename, configuration[:hostname], configuration[:remote_path])
        end

        def download(filename)
          Fulmar::Infrastructure::Service::CopyService.download(local_shell, configuration[:hostname], filename, configuration[:local_path])
        end

        def new_shell(path, hostname = 'localhost')
          shell = Fulmar::Infrastructure::Service::ShellService.new(path, hostname)
          shell.strict = true
          shell.debug = configuration[:debug]
          shell
        end

        def storage
          fail 'You need to set an environment and a target first' unless configuration.ready?
          @storage ||= {}
          @storage[configuration.environment] ||= {}
          @storage[configuration.environment][configuration.target] ||= {}
        end
      end
    end
  end
end
