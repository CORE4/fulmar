require 'singleton'
require 'active_support/core_ext/string/inflections'


module Fulmar
  module Domain
    module Service
      class PluginService
        include Singleton

        def load
          @plugins = {}
          config = ConfigurationService.instance
          config.plugins.each_pair do |name, plugin_config|
            require_plugin(name)
            @plugins[name] = classname(name, :configuration).new(plugin_config)
          end
        end

        def classname(plugin, name = nil)
          "Fulmar::Plugin::#{plugin.to_s.camelize}#{name.nil? ? '' : '::'+name.to_s.camelize}".constantize
        end

        def require_plugin(name)
          require "fulmar-plugin-#{name}"
        end

        def helpers
          @plugins.keys.collect { |plugin| classname(plugin, :dsl_helper) }
        end

        def rake_files
          @plugins.values.collect(&:rake_files).flatten
        end
      end
    end
  end
end
