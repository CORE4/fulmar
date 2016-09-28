require 'yaml'
require 'fulmar/domain/model/project'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/hash/deep_merge'
require 'active_support/hash_with_indifferent_access'

module Fulmar
  module Domain
    module Model
      # Loads and prepares the configuration from the yaml file
      class Configuration
        attr_accessor :environment, :target, :base_path

        def initialize(data, base_path = '', debug = false)
          @data = data
          @base_path = base_path
          @debug = debug
          prepare_data
        end

        # Allow access of configuration via array/hash access methods (read access)
        def [](id)
          ready? ? @data[:environments][@environment][@target][id] : nil
        end

        # Allow access of configuration via array/hash access methods (write access)
        def []=(id, value)
          if ready?
            @data[:environments][@environment][@target][id] = value
          else
            fail 'Environment or target not set. Please set both variables via configuration.environment = \'xxx\' / '\
                 'configuration.target = \'yyy\''
          end
        end

        # Set the environment and target in one call
        def set(environment, target = nil)
          # For convenience, allow something like "environment:target" as string
          if environment.class == String
            fields = environment.split(':')
            @environment = fields.first.to_sym
            @target = fields.size > 1 ? fields[1].to_sym : nil
          else
            @environment = environment
            @target = target unless target.nil?
          end
        end

        # Checks if environment and target are set
        def ready?
          return false if @environment.nil? || @target.nil?
          fail 'Environment is invalid' if @data[:environments][@environment].nil?
          fail 'Target is invalid' if @data[:environments][@environment][@target].nil?
          true
        end

        # Return the project
        def project
          @project ||= Fulmar::Domain::Model::Project.new(@data[:project])
        end

        def plugins
          @data[:plugins] || {}
        end

        # Allows iterating over all targets from all configured environments
        def each
          @data[:environments].each_key do |env|
            @data[:environments][env].each_pair do |target, data|
              yield(env, target, data)
            end
          end
        end

        # Return the combined user and host
        # @todo Is there another way to do this?
        def ssh_user_and_host
          self[:user].blank? ? self[:hostname] : self[:user] + '@' + self[:hostname]
        end

        # Handle dependencies
        # @todo Refactor this to work with the dependencies plugin
        def dependencies(env = nil)
          if env.nil? || !@data[:dependencies].key?(env)
            @data[:dependencies][:all]
          else
            @data[:dependencies][:all].deep_merge(@data[:dependencies][env])
          end
        end

        # Allow access to host list
        def hosts
          @data[:hosts]
        end

        # Check for a feature
        # @todo Do we still need this? Maybe replace this with a "plugin?" method?
        def feature?(feature)
          return @data[:features].include? feature.to_s unless @data[:features].nil?
          case feature
          when :maria
            key? :maria
          else
            false
          end
        end

        # Checks if a configuration key exists in one of the targets
        def key?(key)
          each { |_env, _target, data| return true unless data[key].nil? }
          false
        end

        # Merge another configuration into the currently active one
        # Useful for supplying a default configuration, as values are not overwritten.
        # Hashes are merged.
        # @param [Hash] other
        def merge(other)
          return unless @environment && @target
          @data[:environments][@environment][@target] = other.deep_merge(@data[:environments][@environment][@target])
        end

        protected

        # Prepares the configuration
        def prepare_data
          handle_inheritance
          merge_hosts
          absolutize_paths
        end

        # Merges the :all-configuration into targets.
        # [:environments][:all] into *all* targets
        # [:environments][:something][:all] into all targets from environment :something
        def handle_inheritance
          global_config = @data[:environments].delete(:all) || {}
          environments = @data[:environments].keys
          environments.each do |env|
            environment_config = @data[:environments][env].delete(:all) || {}
            targets = @data[:environments][env].keys
            targets.each do |target|
              local_config = @data[:environments][env][target] || {}
              @data[:environments][env][target] = global_config.deep_merge(environment_config).deep_merge(local_config)
              @data[:environments][env][target][:debug] = @debug
            end
          end
        end

        # Merges the host configuration into the targets referring to it
        def merge_hosts
          each do |env, target, data|
            next if data[:host].nil?
            host = data[:host].to_sym
            @data[:environments][env][target] = @data[:hosts][host].deep_merge(data) unless @data[:hosts][host].nil?
          end
        end

        # Prepends the base to the path if it is not already absolute
        def absolutize(path, base = @base_path)
          return base if path == '.'
          path[0, 1] == '/' ? path : base + '/' + path
        end

        # Checks if a key is a local path
        def local_path?(key)
          key.to_s.split('_').last == 'path' && !key.to_s.include?('remote')
        end

        # Check all keys ending with '_path' and prepend either the
        # @base_path or the local_path from the environment
        def absolutize_paths
          each do |_env, _target, data|
            data.keys.each do |key|
              data[:local_path] = absolutize(data[:local_path]) if data[:local_path]
              if local_path?(key) && data[key].class == String
                data[key] = absolutize(data[key], data[:local_path] || @base_path)
              end
            end
          end
        end
      end
    end
  end
end
