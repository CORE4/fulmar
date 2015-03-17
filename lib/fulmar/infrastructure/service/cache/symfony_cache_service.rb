module Fulmar
  module Infrastructure
    module Service
      module Cache
        # Implements Symfony cache handling
        class SymfonyCacheService
          # @param [Fulmar::Infrastructure::Service::ShellService] shell
          # @param [Hash] config
          def initialize(shell, config)
            @remote_shell = shell
            @config = config
          end

          def clear
            @remote_shell.run [
              "rm -fr app/cache/#{@config[:symfony][:environment]}",
              "php app/console cache:clear --env=#{@config[:symfony][:environment]}"
            ]
          end

          def warmup
            @remote_shell.run "php app/console cache:warmup --env=#{@config[:symfony][:environment]}"
          end
        end
      end
    end
  end
end
