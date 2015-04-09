
require 'fulmar/infrastructure/service/transfer/base'

module Fulmar
  module Infrastructure
    module Service
      module Transfer
        # Implements the rsync transfer
        class Rsync < Base
          DEFAULT_CONFIG = {
            rsync: {
              exclude: nil,
              exclude_file: nil,
              chown: nil,
              chmod: nil,
              delete: true,
              direction: 'up'
            }
          }

          def initialize(config)
            @config = DEFAULT_CONFIG.deep_merge(config)

            if @config[:rsync][:exclude_file].blank? && File.exist?(@config[:local_path] + '/.rsyncignore')
              @config[:rsync][:exclude_file] = @config[:local_path] + '/.rsyncignore'
            end

            super(@config)
          end

          def transfer
            prepare unless @prepared
            @local_shell.run rsync_command
          end

          # Build the rsync command from the given options
          def rsync_command
            if @config[:rsync][:direction] == 'up'
              from = @config[:local_path]
              to = @config.ssh_user_and_host + ':' + @config[:remote_path]
            else
              from = @config.ssh_user_and_host + ':' + @config[:remote_path]
              to = @config[:local_path]
            end

            "rsync #{rsync_command_options.join(' ')} '#{from}/' '#{to}'"
          end

          protected

          # Assembles all rsync command line parameters from the configuration options
          def rsync_command_options
            options = ['-rl']
            options << "--exclude='#{@config[:rsync][:exclude]}'" if @config[:rsync][:exclude]
            options << "--exclude-from='#{@config[:rsync][:exclude_file]}'" if @config[:rsync][:exclude_file]
            options << "--chown='#{@config[:rsync][:chown]}'" if @config[:rsync][:chown]
            options << "--chmod='#{@config[:rsync][:chmod]}'" if @config[:rsync][:chmod]
            options << '--delete' if @config[:rsync][:delete]
            options
          end
        end
      end
    end
  end
end
