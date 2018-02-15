require 'fulmar/domain/service/configuration_service'
require 'fulmar/shell'
require 'colorize'

module Fulmar
  module Domain
    module Service
      module Helper
        # Provides the helper methods used in the tasks
        module CommonHelper
          attr_accessor :environment

          # @return [Fulmar::Domain::Service::ConfigurationService]
          def config
            (@_config_service ||= Fulmar::Domain::Service::ConfigurationService.instance.configuration)
          end

          # @return [Fulmar::Domain::Model::Project]
          def project
            config.project
          end

          # @return [Fulmar::Shell]
          def local_shell
            cache_id = "local_shell-#{config[:local_path]}"
            storage[cache_id] ||= new_shell(config[:local_path])
          end

          # @return [Fulmar::Shell]
          def remote_shell
            cache_id = "remote_shell-#{config[:remote_path]}-#{config.ssh_user_and_host}"
            storage[cache_id] ||= new_shell(config[:remote_path], config.ssh_user_and_host)
          end

          def file_sync
            file_sync_model = Fulmar::FileSync.get_class config
            cache_id = "file_sync-#{file_sync_model.config_hash(config)}"
            storage[cache_id] ||= file_sync_model.new(config.clone)
          end

          def render_templates
            (Fulmar::Domain::Service::TemplateRenderingService.new config).render
          end

          def upload(filename, target = config[:remote_path])
            Fulmar::Infrastructure::Service::CopyService.upload(local_shell, filename, config.ssh_user_and_host, target)
          end

          def download(filename, target = config[:local_path])
            Fulmar::Infrastructure::Service::CopyService.download(local_shell, config.ssh_user_and_host, filename, target)
          end

          def new_shell(path, hostname = 'localhost')
            shell = Fulmar::Shell.new(path, hostname)
            shell.strict = true
            shell.debug = config[:debug]
            shell
          end

          def ssh_config
            storage['ssh_config'] ||= Fulmar::Infrastructure::Service::SSHConfigService.new config
          end

          def storage
            raise 'You need to set an environment and a target first' unless config.ready?
            @storage ||= {}
            @storage[config.environment] ||= {}
            @storage[config.environment][config.target] ||= {}
          end

          def info(text)
            puts(ENV['TERM'] == 'xterm-256color' ? text.blue : "* Info: #{text}") if verbose
          end

          def warning(text)
            STDERR.puts(ENV['TERM'] == 'xterm-256color' ? text.magenta : "* Warning: #{text}")
          end

          def error(text)
            STDERR.puts(ENV['TERM'] == 'xterm-256color' ? text.light_red : "* Error: #{text}")
          end
        end
      end
    end
  end
end
