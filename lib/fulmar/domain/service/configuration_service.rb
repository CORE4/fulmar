require 'yaml'

module Fulmar
  module Domain
    module Service
      # Loads and prepares the configuration from the yaml file
      class ConfigurationService
        FULMAR_FILE = 'Fulmarfile'
        FULMAR_CONFIGURATION = 'FulmarConfiguration'
        DEPLOYMENT_CONFIG_FILE = 'deployment.yml'

        def base_path
          @base_path ||= lookup_base_path
        end

        def configuration
          @config ||= load_configuration
        end

        def method_missing(name)
          environment(name) if configuration[:environments][name]
        end

        def environment(name)
          environment = configuration[:environments][name.to_sym]

          # Make sure a globally set vars get into the environment if not explicitly specified
          configuration[:environments][:all].each do |key|
            environment[key] = configuration[:environments][:all][key] unless environment[key]
          end

          environment
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

        def load_configuration
          YAML.load_file(base_path + '/' + DEPLOYMENT_CONFIG_FILE).symbolize
        end
      end
    end
  end
end
