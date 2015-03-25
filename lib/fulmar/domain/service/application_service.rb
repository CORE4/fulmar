require 'rake'

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

        def wrap_environment
          Proc.new do
            configuration = Fulmar::Domain::Service::ConfigurationService.instance
            environment = configuration.environment
            target = configuration.target

            yield if block_given?

            configuration.environment = environment unless environment.nil?
            configuration.target = target unless target.nil?
          end
        end

        # Add fulmar application tasks
        def fulmar_task_dir
          File.expand_path(File.join(File.dirname(__FILE__), '..', 'task'))
        end
      end
    end
  end
end
