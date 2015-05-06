require 'erb'

module Fulmar
  module Domain
    module Service
      # Tests the configuration
      class ConfigTestService
        def initialize(config)
          @config = config
          @config.load_user_config = false
          @config.reset
        end

        # Runs all methods beginning with test_ and returns the report
        def run
          @report = []
          tests = methods.select { |name| name.to_s[0, 5] == 'test_' }
          tests.each do |test|
            send(test)
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

        def test_project_name_exists
          if @config.configuration[:project][:name].blank?
            add_report 'Project is missing a name', :warning
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

        def test_required_hostnames
          types = %i(rsync rsync_with_version maria)
          @config.each do |env, target, data|
            if types.include?(data[:type]) && data[:hostname].blank?
              @report << {
                message: "#{env}:#{target} requires a hostname (#{data[:hostname]})",
                severity: :error
              }
            end
          end
        end

        def test_vhost_template_is_set
          vhost_template = false

          @config.each do |_env, _target, data|
            vhost_template = true unless data[:vhost_template].blank?
          end

          add_report(
            'The configuration uses the vhost feature but misses a valid configuration for it (missing :vhost_template)',
            :warning
          ) if @config.feature?(:vhost) && !vhost_template
        end

        # Run simple test which only require one configuration
        def test_simple_tests
          @config.each do |env, target, data|
            tests = methods.select { |name| name.to_s[0, 12] == 'simple_test_' }
            tests.each do |test|
              send(test, env, target, data)
            end
          end
        end

        def simple_test_local_path_exists(env, target, data)
          unless File.exist? data[:local_path]
            add_report("#{env}:#{target} has no valid local_path (#{data[:local_path]})", :warning)
          end
        end

        def simple_test_mariadb_feature_is_set(env, target, data)
          if data[:type] == :maria && !@config.feature?(:database)
            @report << {
              message: "#{env}:#{target} uses mysql/mariadb but your config is missing the database feature",
              severity: :notice
            }
          end
        end

        def simple_test_vhost_feature_is_set(env, target, data)
          if data[:vhost_template] && !@config.feature?(:vhost)
            @report << {
              message: "#{env}:#{target} refers to a vhost_template but your config is missing the vhost feature",
              severity: :warning
            }
          end
        end

        def simple_test_maria_db_config_exists(env, target, data)
          if data[:type] == :maria && data[:maria][:database].blank?
            add_report "#{env}:#{target} is missing a database name in maria:database", :error
          end
        end

        def simple_test_remote_path_exists_for_rsync(env, target, data)
          types = [:rsync, :rsync_with_version]
          if types.include?(data[:type]) && data[:remote_path].blank?
            add_report "#{env}:#{target} is missing a remote path", :error
          end
        end

        protected

        def add_report(message, severity)
          @report << {
            message: message,
            severity: severity
          }
        end

        def ssh_hostnames
          `grep -E '^Host [^ *]+$' ~/.ssh/config | sort | uniq | cut -d ' ' -f 2`.split("\n")
        end
      end
    end
  end
end
