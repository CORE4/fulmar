
require 'transfer/base'

module Fulmar
  module Infrastructure
    module Service
      module Transfer

        class Rsync < Fulmar::Infrastructure::Service::Transfer::Base

          DEFAULT_CONFIG = {
              rsync: {
                  exclude: nil,
                  exclude_file: '.rsyncignore',
                  chown: nil,
                  chmod: nil,
                  delete: true
              }
          }

          def initialize(config)
            @config = DEFAULT_CONFIG.deep_merge(config)

            # Add one slash at the end of the local path (rsync specific)
            @config[:local_path] = @config[:local_path].chomp('/') + '/'
          end

          def transfer
            prepare unless @prepared
            @local_shell.run rsync_command
          end

          def rsync_command
            options = [ '-rl' ]
            options << "--exclude='#{@config[:rsync][:exclude]}'" if @config[:rsync][:exclude]
            options << "--exclude-from='#{@config[:rsync][:exclude_file]}'" if @config[:rsync][:exclude_file]
            options << "--chown='#{@config[:rsync][:chown]}'" if @config[:rsync][:chown]
            options << "--chmod='#{@config[:rsync][:chmod]}'" if @config[:rsync][:chmod]
            options << '--delete' if @config[:rsync][:delete]

            "rsync #{options.join(' ')} '#{@config[:local_path]}' '#{ssh_user_and_host}:#{@config[:remote_path]}'"
          end
        end

      end
    end
  end
end