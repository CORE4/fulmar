module Fulmar
  module Domain
    module Service
      class ConfigurationService
        FULMAR_FILE = 'Fulmarfile'
        FULMAR_CONFIGURATION = 'FulmarConfiguration'

        attr_reader :base_path

        def initialize
          @base_path = get_base_path
          puts "Base path: #{@base_path}"
        end

        def get_base_path
          fulmar_file = Fulmar::Service::HelperService.reverse_file_lookup(Dir.pwd, FULMAR_FILE)

          unless fulmar_file
            puts 'Fulmar setup not found. Please run "fulmar setup" to initialize the application in the current directory.'
            exit
          end

          File.dirname(fulmar_file)
        end
      end
    end
  end
end