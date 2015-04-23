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
          @config[:config_templates].each do |template_file|
            template = template_path(template_file)

            renderer = ERB.new(File.read(template))
            result_path = File.dirname(template) + '/' + File.basename(template, '.erb')
            File.open(result_path, 'w') { |config_file| config_file.write(renderer.result(binding)) }
          end
        end

        def template_path(template_file)
          template = "#{@config[:local_path]}/#{template_file}"
          fail "Template filenames must end in .erb - '#{template}' does not" unless template[-4, 4] == '.erb'
          fail "Cannot render missing config file '#{template}'" unless File.exist? template
          template
        end
      end
    end
  end
end
