module Fulmar
  module Infrastructure
    module Service
      # Provides access to composer
      class ComposerService
        DEFAULT_PARAMS = ['--no-dev']

        attr_accessor :shell

        def initialize(shell, custom_path = '/usr/bin/env composer')
          @shell = shell
          @shell.quiet = true
          @path = custom_path
        end

        def execute(command, arguments = DEFAULT_PARAMS)
          @shell.run "#{@path} #{command} #{arguments.join(' ')}"
        end
      end
    end
  end
end
