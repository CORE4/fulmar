require 'pathname'
require 'fulmar/infrastructure/model/transfer/base'

module Fulmar
  module Infrastructure
    module Model
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

          # @param [Fulmar::Domain::Service::ConfigurationService] config
          def initialize(config)
            @config = config
            @config.merge(DEFAULT_CONFIG)

            if @config[:rsync][:exclude_file].blank? && File.exist?(@config[:local_path] + '/.rsyncignore')
              @config[:rsync][:exclude_file] = @config[:local_path] + '/.rsyncignore'
            end

            raise 'Hostname not set. Cannot initialize sync.' if @config[:hostname].nil? || @config[:hostname].empty?

            super(@config)
          end

          def transfer
            prepare unless @prepared
            @local_shell.run rsync_command
          end

          # Build the rsync command from the given options
          def rsync_command
            if @config[:rsync][:direction] == 'up'
              from = absolute_path(@config[:local_path])
              to = @config.ssh_user_and_host + ':' + @config[:remote_path]
            else
              from = @config.ssh_user_and_host + ':' + @config[:remote_path]
              to = absolute_path(@config[:local_path])
            end
            "rsync #{rsync_command_options.join(' ')} '#{from}/' '#{to}'"
          end

          # Gets the absolute release path
          # @return [String] the release directory
          def release_path
            @config[:remote_path]
          end

          protected

          # Get the absolute path of the given path
          # @param [String] path
          # @return [String] absolute path
          def absolute_path(path)
            path = Pathname.new(path)
            return Pathname.new(@config.base_path) + path unless path.absolute?
            path
          end

          def rsync_excludes
            return nil unless @config[:rsync][:exclude]
            excludes = [*@config[:rsync][:exclude]]
            excludes.map { |exclude| "--exclude='#{exclude}'" }.join(' ')
          end

          # Assembles all rsync command line parameters from the configuration options
          def rsync_command_options
            options = ['-rl']
            options << rsync_excludes if rsync_excludes
            options << "--exclude-from='#{@config[:rsync][:exclude_file]}'" if @config[:rsync][:exclude_file]
            options << "--owner --group --chown='#{@config[:rsync][:chown]}'" if @config[:rsync][:chown]
            options << "--chmod='#{@config[:rsync][:chmod]}'" if @config[:rsync][:chmod]
            options << '--delete' if @config[:rsync][:delete]
            options
          end
        end
      end
    end
  end
end
