require 'yaml'
require 'fulmar/domain/model/project'
require 'ruby_wings'
require 'pp'

module Fulmar
  module Domain
    module Model
      # Loads and prepares the configuration from the yaml file
      class Configuration
        attr_accessor :environment, :target, :base_path

        def initialize(data, base_path = '')
          @data = data
          @base_path = base_path
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
              local_config = @data[:environments][env][target]
              @data[:environments][env][target] = global_config.deep_merge(environment_config).deep_merge(local_config)
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
              data[:local_path] = absolutize(data[:local_path])
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
