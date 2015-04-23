require 'fulmar/domain/service/configuration_service'
require 'colorize'

module Fulmar
  module Domain
    module Service
      module Helper
        # Provides the helper methods used in the tasks
        module CommonHelper
          attr_accessor :environment

          def full_configuration
            configuration.configuration
          end

          def configuration
            (@_config_service ||= Fulmar::Domain::Service::ConfigurationService.instance)
          end

          def composer(command, arguments = Fulmar::Infrastructure::Service::ComposerService::DEFAULT_PARAMS)
            (storage['composer'] ||= Fulmar::Infrastructure::Service::ComposerService.new(local_shell)).execute(command, arguments)
          end

          def local_shell
            storage['local_shell'] ||= new_shell(configuration[:local_path])
          end

          def remote_shell
            storage['remote_shell'] ||= new_shell(configuration[:remote_path], configuration.ssh_user_and_host)
          end

          def file_sync
            storage['file_sync'] ||= Fulmar::FileSync.create_transfer configuration
          end

          def render_templates
            (Fulmar::Domain::Service::ConfigRenderingService.new configuration).render
          end

          def git
            storage['git'] ||= Fulmar::Infrastructure::Service::GitService.new configuration
          end

          def upload(filename)
            Fulmar::Infrastructure::Service::CopyService.upload(local_shell, filename, configuration.ssh_user_and_host, configuration[:remote_path])
          end

          def download(filename)
            Fulmar::Infrastructure::Service::CopyService.download(local_shell, configuration.ssh_user_and_host, filename, configuration[:local_path])
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

          def info(text)
            puts (ENV['TERM'] == 'xterm-256color' ? text.blue : "* Info: #{text}") if verbose
          end

          def warning(text)
            STDERR.puts (ENV['TERM'] == 'xterm-256color' ? text.magenta : "* Warning: #{text}")
          end

          def error(text)
            STDERR.puts (ENV['TERM'] == 'xterm-256color' ? text.light_red : "* Error: #{text}")
          end
        end
      end
    end
  end
end
