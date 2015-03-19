require 'rake'

module Fulmar
  module Domain
    module Service
      # The main application which extends rake
      class ApplicationService < Rake::Application
        def initialize
          super
          @rakefiles = %w(fulmarfile Fulmarfile fulmarfile.rb Fulmarfile.rb)
          @rakefiles.push(*fulmar_tasks)
        end

        def name
          'fulmar'
        end

        def run
          Rake.application = self
          super
        end

        def define_task(task_class, *args, &block)
          super(task_class, *args, &wrap_environment(&block))
        end

        def wrap_environment
          Proc.new do
            configuration = Fulmar::Domain::Service::ConfigurationService.instance
            environment = configuration.environment
            target = configuration.target

            yield

            configuration.environment = environment
            configuration.target = target
          end
        end

        # Add fulmar application tasks
        def fulmar_tasks
          Dir.glob(File.expand_path(File.join(File.dirname(__FILE__), '../', 'task')) + '/*.rake')
        end
      end
    end
  end
end
