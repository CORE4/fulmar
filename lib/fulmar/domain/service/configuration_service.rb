require 'yaml'
require 'pp'
require 'fulmar/domain/model/project'
require 'fulmar/domain/model/configuration'
require 'active_support/core_ext/hash/keys'

module Fulmar
  module Domain
    module Service
      # Loads and prepares the configuration from the yaml file
      # TODO: Clone target configuration when used as a parameter to another service so an environment change won't affect it
      # Not Sure if that is actually a god idea
      class ConfigurationService
        FULMAR_FILE = 'Fulmarfile'
        FULMAR_CONFIGURATION = 'FulmarConfiguration'
        FULMAR_CONFIGURATION_DIR = 'Fulmar'
        DEPLOYMENT_CONFIG_FILE = 'deployment.yml'

        BLANK_CONFIG = {
          project: {},
          environments: {},
          features: {},
          hosts: {},
          dependencies: { all: {} }
        }

        include Singleton

        attr_reader :environment, :target
        attr_accessor :load_user_config, :debug

        def initialize
          @load_user_config = true
        end

        def base_path
          @base_path ||= lookup_base_path
        end

        def configuration
          @config ||= load_configuration
        end

        # Merge another configuration into the currently active one
        # Useful for supplying a default configuration, as values are not overwritten.
        # Hashes are merged.
        # @param [Hash] other
        def merge(other)
          return unless @environment && @target
          configuration[:environments][@environment][@target] = other.deep_merge(configuration[:environments][@environment][@target])
        end

        def config_files
          files = Dir.glob(File.join(base_path, FULMAR_CONFIGURATION_DIR, '*.config.yml')).sort
          files << "#{ENV['HOME']}/.fulmar.yml" if File.exist?("#{ENV['HOME']}/.fulmar.yml") && @load_user_config
          files
        end

        # Reset the loaded configuration, forcing a reload
        # this is currently used for reloading the config without the user config file
        # to test the project configuration
        def reset
          @config = nil
        end

        protected

        def lookup_base_path
          fulmar_file = Fulmar::Service::HelperService.reverse_file_lookup(Dir.pwd, FULMAR_FILE)

          unless fulmar_file
            puts 'Fulmar setup not found. Please run "fulmar setup" to initialize the application in the current directory.'
            exit
          end

          File.dirname(fulmar_file)
        end

        # Loads the configuration from the YAML file and populates all targets
        def load_configuration
          config = BLANK_CONFIG
          config_files.each do |config_file|
            config = config.deep_merge((YAML.load_file(config_file) || {}).deep_symbolize_keys)
          end
          check_version(config[:project][:fulmar_version])
          Fulmar::Domain::Model::Configuration.new(config)
        end

        # @todo Move to configuration model if I know what this was or if it is relevant
        def prepare_dependencies
          @config[:dependencies].each_pair do |_env, repos|
            repos.each_pair do |_name, repo|
              next if repo[:path].blank?
              full_path = File.expand_path("#{base_path}/#{repo[:path]}")
              repo[:path] = full_path unless repo[:path][0,1] == '/'
            end
          end
        end

        def check_version(version)
          return if version.nil?
          unless  Gem::Dependency.new('', version).match?('', Fulmar::VERSION)
            fail "Project requires a newer version of fulmar: #{@config[:project][:fulmar_version]}"
          end
        end
      end
    end
  end
end
