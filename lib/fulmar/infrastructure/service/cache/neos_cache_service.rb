module Fulmar
  module Infrastructure
    module Service
      # Implements Neos cache handling
      class NeosService
        # @param [Fulmar::Infrastructure::Service::ShellService] shell
        # @param [Hash] config
        def initialize(shell, config)
          @remote_shell = shell
          @config = config
        end

        def cache_clear
          @remote_shell.run "FLOW_CONTEXT=\"#{@config[:neos][:environment]}\" ./flow flow:cache:flush --force"
        end

        def cache_warmup
          @remote_shell.run "FLOW_CONTEXT=\"#{@config[:neos][:environment]}\" ./flow flow:cache:warmup"
        end

        def site_export(filename = export_filename)
          @remote_shell.run "FLOW_CONTEXT=\"#{@config[:neos][:environment]}\" ./flow typo3.neos:site:export --filename \"#{filename}\""
          filename
        end

        def site_import(filename)
          @remote_shell.run "FLOW_CONTEXT=\"#{@config[:neos][:environment]}\" ./flow typo3.neos:site:import --filename \"#{filename}\""
        end

        def flow(command)
          @remote_shell.run "FLOW_CONTEXT=\"#{@config[:neos][:environment]}\" ./flow #{command}"
        end

        protected

        def export_filename
          "export_#{Time.now.strftime('%Y-%m-%dT%H%M%S')}.xml"
        end
      end
    end
  end
end
