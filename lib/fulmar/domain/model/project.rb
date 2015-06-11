module Fulmar
  module Domain
    module Model
      # Provides information about the current project
      class Project
        attr_reader :name, :description, :license, :authors, :config

        def initialize(config)
          @name = config[:name] || '<unnamed>'
          @description = config[:description] || '<no description>'
          @license = config[:license] || 'proprietary'
          @authors = config[:authors] || []
          @config = config[:config] || {}
        end
      end
    end
  end
end
