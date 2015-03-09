require 'rake'

module Fulmar
  module Domain
    module Service
      class ApplicationService < Rake::Application

        def initialize
          super
          @rakefiles = %w{fulmarfile Fulmarfile fulmarfile.rb Fulmarfile.rb}
          @rakefiles.push(*fulmar_tasks)
        end

        def name
          'fulmar'
        end

        def run
          Rake.application = self
          super
        end

        # Add fulmar application tasks
        def fulmar_tasks
          Dir.glob(File.expand_path(File.join(File.dirname(__FILE__),'../','task')) + '/*.rake')
        end
      end
    end
  end
end