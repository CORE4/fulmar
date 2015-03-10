require 'yaml'

module Fulmar
  module Domain
    module Service
      class ConfigurationService
        FULMAR_FILE = 'Fulmarfile'
        FULMAR_CONFIGURATION = 'FulmarConfiguration'
        DEPLOYMENT_CONFIG_FILE = 'deployment.yml'

        def initialize
          puts "Base path: #{base_path}"
        end

        def base_path
          @base_path ||= get_base_path
        end

        def configuration
          @config ||= load_configuration
        end

        def method_missing(name)
          if configuration[:environments][name]
            prepare_environment(name)
          end
        end

        protected

        def get_base_path
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

        def prepare_environment(name)
          environment = configuration[:environments][name.to_sym]

          # Make sure a globally set vars get into the environment if not explicitly specified
          global_vars = [:local_path, :debug]
          global_vars.each do |key|
            if configuration[:environments][:all][key] and not environment[key]
              environment[key] = configuration[:environments][:all][key]
            end
          end
          environment
        end
      end
    end
  end
end