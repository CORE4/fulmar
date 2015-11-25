require 'singleton'
require 'active_support/core_ext/string/inflections'

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
          config.plugins.each_pair do |name, plugin_config|
            require_plugin(name)
            @plugins[name] = classname(name, :configuration).new(plugin_config)
          end
        end

        def classname(plugin, name = nil)
          "Fulmar::Plugin::#{plugin.to_s.camelize}#{name.nil? ? '' : '::'+name.to_s.camelize}".constantize
        end

        def require_plugin(name)
          require "fulmar/plugin/#{name}/configuration"
        end

        def helpers
          @plugins.keys.select { |plugin| classname(plugin).constants.include? (:DslHelper) }.collect do |plugin|
            classname(plugin, :DslHelper)
          end
        end

        def rake_files
          @plugins.values.collect(&:rake_files).flatten
        end
      end
    end
  end
end
