require 'fulmar/shell'

module Fulmar
  module Infrastructure
    module Service
      # Adds entries to the ssh config and checks for existing ones
      class SSHConfigService
        CONFIG_FILE = "#{ENV['HOME']}/.ssh/config"

        def initialize(config)
          @config = config
        end

        def add_hosts
          @config.configuration[:hosts].values.each do |data|
            unless config_valid?(data)
              puts "Skipping #{data[:hostname]}, config not sufficient." if @config[:debug]
              next
            end
            if host_exists?(data[:hostname])
              puts "Host #{data[:hostname]} exists, skipping..." if @config[:debug]
            else
              add_host(data[:hostname], data)
            end
          end
        end

        # Parses the users ssh config for an existing hostname
        def host_exists?(hostname)
          config_file = File.open(CONFIG_FILE, 'r')
          while (line = config_file.gets)
            if /\s*Host #{hostname.gsub('.', '\\.')}\s*$/.match(line)
              config_file.close
              return true
            end
          end
          config_file.close
          false
        end

        # Adds a host to the ssh config file
        def add_host(hostname, host_config = {})
          puts "Adding host #{host_config[:hostname]}..." if @config[:debug]
          config_file = File.open(CONFIG_FILE, 'a')

          config_file.puts "\n" # Add some space between this and the second last entry
          config_file.puts "# Automatically generated by fulmar for project #{@config.configuration[:project][:name] || '<unnamed>'}"
          config_file.puts "Host #{hostname}"
          config_file.puts "    Hostname #{host_config[:config_hostname]}" unless host_config[:config_hostname].blank?
          config_file.puts "    Port #{host_config[:config_port]}" unless host_config[:config_port].blank?
          config_file.puts "    User #{host_config[:config_user]}" unless host_config[:config_user].blank?
          config_file.puts "    ProxyCommand #{host_config[:config_proxycommand]}" unless host_config[:config_proxycommand].blank?

          config_file.close
        end

        private

        def config_valid?(host_config)
          (!host_config[:hostname].blank? && !host_config[:config_hostname].blank?)
        end
      end
    end
  end
end
