require 'yaml'

module Fulmar
  module Domain
    module Service
      # Loads and prepares the configuration from the yaml file
      # TODO: Clone target configuration when used as a parameter to another service so an environment change won't affect it
      class ConfigurationService
        FULMAR_FILE = 'Fulmarfile'
        FULMAR_CONFIGURATION = 'FulmarConfiguration'
        DEPLOYMENT_CONFIG_FILE = 'deployment.yml'

        include Singleton

        attr_reader :environment, :target

        def initialize
          @environment = nil
          @target = nil
        end

        # Allow access of configuration via array/hash access methods (read access)
        def [](id)
          ready? ? configuration[:environments][@environment][@target][id] : nil
        end

        # Allow access of configuration via array/hash access methods (write access)
        def []=(id, value)
          if ready?
            configuration[:environments][@environment][@target][id] = value
          else
            fail 'Environment or target not set. Please set both variables via configuration.environment = \'xxx\' / '\
                 'configuration.target = \'yyy\''
            end
        end

        def to_hash
          ready? ? configuration[:environments][@environment][@target] : configuration
        end

        def base_path
          @base_path ||= lookup_base_path
        end

        def configuration
          @config ||= load_configuration
        end

        def method_missing(name)
          environment(name) if configuration[:environments][name]
        end

        def environment=(env)
          @environment = env ? env.to_sym : nil
        end

        def target=(target)
          @target = target ? target.to_sym : nil
        end

        def ready?
          !@environment.nil? && !@target.nil?
        end

        # Merge another configuration into the currently active one
        # Useful for supplying a default configuration, as values are not overwritten.
        # Hashes are merged.
        # @param [Hash] other
        def merge(other)
          if @environment && @target
            configuration[:environments][@environment][@target] = other.deep_merge(configuration[:environments][@environment][@target])
          end
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

        # Fills a target with all globally set variables so all necessary information
        # is found within each target
        def fill_target(env, target)
          @config[:environments][env][target] = @config[:environments][:all].deep_merge(@config[:environments][env][target])

          unless @config[:environments][env][target][:host].blank?
            host = @config[:environments][env][target][:host].to_sym
            if @config[:hosts] && @config[:hosts][host]
              @config[:hosts][host].each do
                @config[:environments][env][target] = @config[:hosts][host].deep_merge(@config[:environments][env][target])
              end
            else
              fail "Host #{host} is not configured."
            end
          end
        end

        # Loads the configuration from the YAML file and populates all targets
        def load_configuration
          @config = YAML.load_file(base_path + '/' + DEPLOYMENT_CONFIG_FILE).symbolize

          # Iterate over all environments and targets to prepare them
          @config[:environments].each_key do |env|
            next if env == :all
            @config[:environments][env].each_key { |target| fill_target(env, target) }
          end
          @config
        end
      end
    end
  end
end
