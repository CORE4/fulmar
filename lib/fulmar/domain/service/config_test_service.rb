require 'erb'

module Fulmar
  module Domain
    module Service
      # Tests the configuration
      class ConfigTestService
        include Fulmar::Domain::Model

        def initialize(config)
          @config = config
          @tests = {}
        end

        def test(name, &block)
          @tests[name] = block
        end

        # Runs all methods beginning with test_ and returns the report
        def run
          test_dirs = ["#{File.dirname(__FILE__)}/config_tests/"]
          test_files = test_dirs.collect{ |dir| Dir.glob("#{dir}/*.rb") }.flatten
          test_files.each do |file|
            require file
          end

          results = []
          pp @tests
          @tests.each_pair do |name, test|
            puts "Running #{name}..."
            result = test.call(@config)
            pp result
            if result
              results << { severity: result[0], message: result[1] }
            else
              nil
            end
          end
          results.reject!(&:nil?)
        end

        protected

        def ssh_hostnames
          `grep -E '^Host [^ *]+$' ~/.ssh/config | sort | uniq | cut -d ' ' -f 2`.split("\n")
        end
      end
    end
  end
end
