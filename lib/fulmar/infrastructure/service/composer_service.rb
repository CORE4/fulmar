module Fulmar
  module Infrastructure
    module Service
      # Provides access to composer
      class ComposerService
        def initialize(shell, custom_path = '/usr/bin/env composer')
          @local_shell = shell
          @path = custom_path
        end

        def execute(command, arguments = %w(--no-dev -q))
          @local_shell.run "#{@path} #{command} #{arguments.join(' ')}"
        end
      end
    end
  end
end
