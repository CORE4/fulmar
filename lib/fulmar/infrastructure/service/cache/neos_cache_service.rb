module Fulmar
  module Infrastructure
    module Service
      module Cache
        # Implements Neos cache handling
        class NeosCacheService
          # @param [Fulmar::Infrastructure::Service::ShellService] shell
          # @param [Hash] config
          def initialize(shell, config)
            @remote_shell = shell
            @config = config
          end

          def clear
            @remote_shell.run "FLOW_CONTEXT=\"#{@config[:neos][:environment]}\" ./flow flow:cache:flush --force"
          end

          def warmup
            @remote_shell.run "FLOW_CONTEXT=\"#{@config[:neos][:environment]}\" ./flow flow:cache:warmup"
          end
        end
      end
    end
  end
end
