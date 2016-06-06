require 'fulmar/shell'

module Fulmar
  module Infrastructure
    module Service
      # Adds entries to the ssh config and checks for existing ones
      class SSHConfigService
        CONFIG_FILE = "#{ENV['HOME']}/.ssh/config"
        KNOWN_HOST_FILE = "#{ENV['HOME']}/.ssh/known_hosts"
        # @todo: Get rid of this layer (Version 2?)
        CONFIG_MAP = {
          hostname: 'Hostname',
          port: 'Port',
          user: 'User',
          proxycommand: 'ProxyCommand',
          checkhostip: 'CheckHostIP',
          stricthostkeychecking: 'StrictHostKeyChecking',
          identityfile: 'IdentityFile',
          userknownhostfile: 'UserKnownHostsFile',
          loglevel: 'LogLevel',
          forwardagent: 'ForwardAgent'
        }

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
              add_host(data[:hostname], data[:ssh_config])
            end
          end
        end

        def remove_known_host(hostname)
          input_file = File.open(KNOWN_HOST_FILE, 'r')
          output_file = File.open(KNOWN_HOST_FILE + '.temp', 'w')
          while (line = input_file.gets)
            output_file.puts(line) unless /^\[?#{hostname.gsub('.', '\\.')}(?:\]:\d+)?[ ,]/.match(line)
          end
          input_file.close
          output_file.close
          FileUtils.mv(KNOWN_HOST_FILE + '.temp', KNOWN_HOST_FILE)
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
        def add_host(hostname, ssh_config = {})
          puts "Adding host #{hostname}..." if @config[:debug]
          config_file = File.open(CONFIG_FILE, 'a')

          unless ssh_config[:identityfile].blank? or ssh_config[:identityfile][0, 1] == '/'
            ssh_config[:identityfile] = @config.base_path + '/' + ssh_config[:identityfile]
          end

          config_file.puts "\n" # Add some space between this and the second last entry
          config_file.puts "# Automatically generated by fulmar for project #{@config.project.description}"
          config_file.puts "Host #{hostname}"
          CONFIG_MAP.keys.each do |key|
            config_file.puts "    #{CONFIG_MAP[key]} #{ssh_config[key]}" unless ssh_config[key].blank?
          end

          config_file.close
        end

        private

        def config_valid?(host_config)
          (!host_config[:hostname].blank? && !host_config[:ssh_config].nil?)
        end
      end
    end
  end
end
