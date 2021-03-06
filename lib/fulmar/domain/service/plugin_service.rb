require 'singleton'
require 'active_support/core_ext/string/inflections'
require 'fulmar/domain/service/configuration_service'

module Fulmar
  module Domain
    module Service
      class PluginService
        include Singleton

        def self.instance
          @@instance ||= new
        end

        def initialize
          @plugins = {}
          config = ConfigurationService.instance.configuration

          if config.plugins.class == Array
            raise 'Plugin list must not be an array. Have a look at https://github.com/CORE4/fulmar#plugins for ' +
                  'more information'
          end

          config.plugins.each_pair do |name, plugin_config|
            puts "Loading plugin '#{name}'..." if config.debug
            require_plugin(name)
            @plugins[name] = classname(name, :configuration).new(plugin_config)
          end

        end

        def classname(plugin, name = nil)
          "Fulmar::Plugin::#{class_map[plugin.to_s.downcase]}#{name.nil? ? '' : '::'+name.to_s.camelize}".constantize
        end

        def class_map
          map = {}
          Fulmar::Plugin.constants.each do |classname|
            map[classname.to_s.downcase] = classname.to_s
          end
          map
        end

        def require_plugin(name)
          require "fulmar/plugin/#{name}/configuration"
        end

        def helpers
          @plugins.keys.select { |plugin| classname(plugin).constants.include? (:DslHelper) }.collect do |plugin|
            classname(plugin, :DslHelper)
          end
        end

        def test_files
          @plugins.values.select{|plugin| plugin.respond_to?(:test_files) }.collect(&:test_files).flatten
        end

        def rake_files
          @plugins.values.collect(&:rake_files).flatten
        end
      end
    end
  end
end
