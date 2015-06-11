require 'yaml'
require 'pp'
require 'fulmar/domain/model/project'

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
        attr_accessor :load_user_config

        def initialize
          @environment = nil
          @target = nil
          @load_user_config = true
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

        def project
          @project ||= Fulmar::Domain::Model::Project.new(configuration[:project])
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

        def ssh_user_and_host
          self[:user].blank? ? self[:hostname] : self[:user] + '@' + self[:hostname]
        end

        def dependencies(env = nil)
          if env.nil? || !@config[:dependencies].has_key?(env)
            @config[:dependencies][:all]
          else
            @config[:dependencies][:all].deep_merge(@config[:dependencies][env])
          end
        end

        def ready?
          return false if @environment.nil? || @target.nil?
          fail 'Environment is invalid' if configuration[:environments][@environment].nil?
          fail 'Target is invalid' if configuration[:environments][@environment][@target].nil?
          true
        end

        def feature?(feature)
          return configuration[:features].include? feature.to_s unless configuration[:features].nil?
          case feature
          when :database
            any? { |data| data[:type] == 'maria' }
          else
            false
          end
        end

        def each
          configuration[:environments].each_key do |env|
            configuration[:environments][env].each_pair do |target, data|
              yield(env, target, data)
            end
          end
        end

        def any?
          if block_given?
            each { |_env, _target, data| return true if yield(data) }
            false
          else
            configuration[:environments].any?
          end
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

        # Fills a target with all globally set variables so all necessary information
        # is found within each target
        def fill_target(env, target)
          @config[:environments][env][target] = @config[:environments][:all].deep_merge(@config[:environments][env][target]) if @config[:environments][:all]

          return if @config[:environments][env][target][:host].blank?

          host = @config[:environments][env][target][:host].to_sym
          return unless @config[:hosts] && @config[:hosts][host]
          @config[:hosts][host].each do
            @config[:environments][env][target] = @config[:hosts][host].deep_merge(@config[:environments][env][target])
          end
        end

        # Loads the configuration from the YAML file and populates all targets
        def load_configuration
          @config = BLANK_CONFIG
          config_files.each do |config_file|
            @config = @config.deep_merge((YAML.load_file(config_file) || {}).symbolize)
          end

          prepare_environments
          prepare_dependencies
          # Iterate over all environments and targets to prepare them
          @config[:environments].delete(:all)
          @config
        end

        def prepare_environments
          @config[:environments].each_key do |env|
            next if env == :all
            @config[:environments][env].each_key do |target|
              fill_target(env, target)
              check_path(env, target)
            end
          end
        end

        def prepare_dependencies
          @config[:dependencies].each_pair do |_env, repos|
            repos.each_pair do |_name, repo|
              next if repo[:path].blank?
              full_path = File.expand_path("#{base_path}/#{repo[:path]}")
              repo[:path] = full_path unless repo[:path][0,1] == '/'
            end
          end
        end

        def check_path(env, target)
          return if @config[:environments][env][target][:local_path].blank?
          @config[:environments][env][target][:local_path] = File.expand_path(@config[:environments][env][target][:local_path])
        end
      end
    end
  end
end
