module Fulmar
  module Infrastructure
    module Service
      module Cache
        # Implements no cache handling
        class DummyCacheService
          # @param [Fulmar::Infrastructure::Service::ShellService] shell
          # @param [Hash] config
          def initialize(shell, config)
            @remote_shell = shell
            @config = config
          end

          def clear
            true
          end

          def warmup
            true
          end
        end
      end
    end
  end
end
