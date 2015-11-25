require 'rake'
require 'fulmar/domain/service/plugin_service'

module Fulmar
  module Domain
    module Service
      # The main application which extends rake
      class ApplicationService < Rake::Application
        def initialize
          super
          @rakefiles = %w(fulmarfile Fulmarfile fulmarfile.rb Fulmarfile.rb)
        end

        def name
          'fulmar'
        end

        def run
          Rake.application = self
          super
        end

        def init
          super
          options.rakelib << fulmar_task_dir
          options.rakelib << 'Fulmar'
        end

        def define_task(task_class, *args, &block)
          super(task_class, *args, &wrap_environment(&block))
        end

        def raw_load_rakefile
          glob("#{fulmar_task_dir}/initialization/*.rake") do |name|
            Rake.load_rakefile name
          end
          Fulmar::Domain::Service::PluginService.instance.rake_files.each do |name|
            Rake.load_rakefile name
          end
          super
        end

        def wrap_environment
          proc do |t, args|
            configuration = Fulmar::Domain::Service::ConfigurationService.instance
            environment = configuration.environment
            target = configuration.target

            yield(t, args) if block_given?

            configuration.environment = environment unless environment.nil?
            configuration.target = target unless target.nil?
          end
        end

        # Add fulmar application tasks
        def fulmar_task_dir
          File.expand_path(File.join(File.dirname(__FILE__), '..', 'task'))
        end

        def standard_rake_options
          options = super
          options.reject { |option| option[0] == '--version' }
          options << [
            '--version',
            '-V',
            'Display the program version.',
            lambda do |_value|
              puts "fulmar #{Fulmar::VERSION} (using rake, version #{RAKEVERSION})"
              exit
            end
          ]
          options << [
              '--debug',
              nil,
              'Run in debug mode.',
              lambda do |_value|
                configuration = Fulmar::Domain::Service::ConfigurationService.instance
                configuration.debug = true
              end
          ]
          options
        end
      end
    end
  end
end
