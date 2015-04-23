require 'erb'

module Fulmar
  module Domain
    module Service
      # Renders templates of config files
      class ConfigTestService

        def initialize(config)
          @config = config
          @config.load_user_config = false
          @config.reset
        end

        def run
          @report = []
          tests = self.methods.select { |name| name.to_s[0, 5] == 'test_' }
          tests.each do |test|
            self.send(test)
          end
          @report
        end

        def test_hostnames_exist
          @config.each do |env, target, data|
            if data[:hostname].blank? && !data[:host].blank?
              @report << {
                message: "#{env}:#{target} has a host (#{data[:host]}) but is missing a hostname",
                severity: :warning
              }
            end
          end
        end

        def test_hostnames_in_ssh_config
          hostnames = ssh_hostnames

          @config.each do |env, target, data|
            next if data[:hostname].blank?

            unless hostnames.include? data[:hostname]
              @report << {
                message: "#{env}:#{target} has a hostname (#{data[:hostname]}) which is not found in your ssh config",
                severity: :info
              }
            end
          end
        end

        protected

        def ssh_hostnames
          `grep -E '^Host [^ *]+$' ~/.ssh/config | sort | uniq | cut -d ' ' -f 2`.split("\n")
        end
      end
    end
  end
end
