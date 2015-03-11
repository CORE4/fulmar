
require 'fulmar_shell'

module Fulmar
  module Infrastructure
    module Service
      module Transfer

        class Base

          DEFAULT_CONFIG = {
              debug: false,
              host: nil,
              user: '',
              password: '',
              remote_path: nil,
              local_path: '.',
              type: :rsync_with_versions
          }

          attr_accessor :config

          def initialize(config)
            @config = DEFAULT_CONFIG.merge(config)
            @prepared = false
          end

          # Test the supplied config for required parameters
          def test_config
            required = [:host, :remote_path, :local_path]
            required.each {|key| raise "Configuration is missing required setting '#{key}'." if !@config.include?(key) or @config[key].empty? }
          end

          def prepare
            @local_shell = Fulmar::Infrastructure::Service::ShellService.new @config[:local_path]
            @local_shell.debug = @config[:debug]
            @prepared = true
          end

          def publish
            # Placeholder for consistent api, currently only implemented in rsync_with_versions
            true
          end

          protected

          def ssh_user_and_host
            (@config[:user] and not @config[:user].empty?) ? @config[:user] + '@' + @config[:host] : @config[:host]
          end
        end

      end
    end
  end
end