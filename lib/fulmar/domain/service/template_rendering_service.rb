require 'erb'

module Fulmar
  module Domain
    module Service
      # Renders templates of config files
      class TemplateRenderingService
        def initialize(config)
          @config = config
        end

        def render
          return unless @config[:templates]
          @config[:templates].each do |template_file|
            template = template_path(template_file)

            renderer = ERB.new(File.read(template))
            result_path = File.dirname(template) + '/' + File.basename(template, '.erb')
            File.open(result_path, 'w') { |config_file| config_file.write(renderer.result(binding)) }
          end
        end

        def template_path(template_file)
          template = "#{@config[:local_path]}/#{template_file}"
          raise "Template filenames must end in .erb - '#{template}' does not" unless template[-4, 4] == '.erb'
          raise "Cannot render missing config file '#{template}'" unless File.exist? template
          template
        end
      end
    end
  end
end
