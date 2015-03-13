module Fulmar
  module Infrastructure
    module Service
      # Provides access to composer
      class ComposerService
        def initialize(custom_path = '/usr/bin/env composer')
          @path = custom_path
        end

        def execute(command, arguments = [])
          system "#{@path} #{command} #{arguments.join(' ')} > /dev/null"
        end
      end
    end
  end
end
