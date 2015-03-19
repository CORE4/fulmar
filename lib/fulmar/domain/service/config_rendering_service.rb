require 'erb'

module Fulmar
  module Domain
    module Service
      # Renders templates of config files
      class ConfigRenderingService
        def initialize(config)
          @config = config
        end

        def render
          return unless @config[:config_templates]
          @config[:config_templates].each do |template|
            fail "Template filenames must end in .erb - '#{template}' does not" unless template[-4, 4] == '.erb'
            fail "Cannot render missing config file '#{template}'" unless File.exist? template

            renderer = ERB.new(File.read(template))
            result_path = File.dirname(template) + '/' + File.basename(template, '.erb')
            File.open(result_path, 'w') { |config_file| config_file.write(renderer.result(binding)) }
          end
        end
      end
    end
  end
end
