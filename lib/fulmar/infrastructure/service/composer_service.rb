module Fulmar
  module Infrastructure
    module Service
      # Provides access to composer
      class ComposerService
        DEFAULT_PARAMS = ['--no-dev']

        def initialize(shell, custom_path = '/usr/bin/env composer')
          @local_shell = shell
          @local_shell.quiet = true
          @path = custom_path
        end

        def execute(command, arguments = DEFAULT_PARAMS)
          @local_shell.run "#{@path} #{command} #{arguments.join(' ')}"
        end
      end
    end
  end
end
