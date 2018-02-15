require 'fulmar/shell'
require 'digest'

module Fulmar
  module Infrastructure
    module Model
      module Transfer
        # Abstract class for all transfers, provides common methods
        class Base
          DEFAULT_CONFIG = {
            debug: false,
            user: '',
            password: '',
            remote_path: nil,
            local_path: '.',
            type: :rsync_with_versions
          }.freeze

          attr_accessor :config

          # @param [Fulmar::Domain::Service::ConfigurationService] config
          def initialize(config)
            @config = config
            @config.merge(DEFAULT_CONFIG)

            # Remove trailing slashes
            @config[:local_path] = @config[:local_path].chomp('/') if @config[:local_path]
            @config[:remote_path] = @config[:remote_path].chomp('/') if @config[:remote_path]

            @prepared = false
          end

          # Test the supplied config for required parameters
          def test_config
            required = %i[host remote_path local_path]
            required.each { |key| raise "Configuration is missing required setting '#{key}'." if @config.blank? }
            raise ':remote_path must be absolute' if @config[:remote_path][0, 1] != '/'
          end

          def prepare
            @local_shell = Fulmar::Shell.new @config[:local_path]
            @local_shell.strict = true
            @local_shell.debug = @config[:debug]
            @prepared = true
          end

          def publish
            # Placeholder for consistent api, currently only implemented in rsync_with_versions
            true
          end

          # Generate a hash over all relevant config values to allow more precise caching
          def self.config_hash(config)
            id_string = self.class.to_s
            id_string << DEFAULT_CONFIG.keys.map { |key| config[key].to_s }.join('-')
            id_string << config[:hostname]
            Digest::SHA256.hexdigest id_string
          end
        end
      end
    end
  end
end
