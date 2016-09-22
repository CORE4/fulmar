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

        def target_test(name, &block)
          @tests[name] = Proc.new do
            results = []
            @config.each do |env, target, _data|
              @config.set env, target
              result = block.call(@config)
              if result
                result[:message] = "in [#{env}:#{target}]: #{result[:message]}"
                results << result
              end
            end
            results.reject(&:nil?)
          end

        end

        def global_test(name, &block)
          @tests[name] = block
        end

        # Runs all methods beginning with test_ and returns the report
        def run
          test_dirs = ["#{File.dirname(__FILE__)}/config_tests/"]
          test_files = test_dirs.collect{ |dir| Dir.glob("#{dir}/*.rb") }.flatten
          test_files.each do |file|
            eval File.read(file)
          end

          results = []
          @tests.each_pair do |name, test|
            results << test.call(@config)
          end
          results.reject!(&:nil?)
          results.reject!(&:empty?)
          results.flatten!
          results
        end

        protected

        def ssh_hostnames
          @ssh_hostnames ||= `grep -E '^Host [^ *]+$' ~/.ssh/config | sort | uniq | cut -d ' ' -f 2`.split("\n")
        end
      end
    end
  end
end
