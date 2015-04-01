module Fulmar
  module Infrastructure
    module Service
      # Provides access to composer
      class ComposerService
        def initialize(shell, custom_path = '/usr/bin/env composer')
          @local_shell = shell
          @path = custom_path
        end

        def execute(command, arguments = ['--no-dev'])
          @local_shell.run "#{@path} #{command} #{arguments.join(' ')} > /dev/null"
        end
      end
    end
  end
end
