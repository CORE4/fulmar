require 'fulmar/shell'
require 'pp'
require 'diffy'
require 'active_support/core_ext/object/blank'

module Fulmar
  module Infrastructure
    module Service
      # Adds entries to the ssh config and checks for existing ones
      class SSHConfigService
        DEFAULT_CONFIG_FILE = "#{ENV['HOME']}/.ssh/config"
        DEFAULT_KNOWN_HOSTS_FILE = "#{ENV['HOME']}/.ssh/known_hosts"

        attr_accessor :config_file, :known_host_file, :quiet

        def initialize(config, config_file = DEFAULT_CONFIG_FILE, known_hosts_file = DEFAULT_KNOWN_HOSTS_FILE)
          @config = config
          @config_file = config_file
          @known_hosts_file = known_hosts_file
          @quiet = false
        end

        def changed?
          File.read(@config_file) != File.read("#{@config_file}.bak")
        end

        def diff(type = :color)
          before = File.read("#{@config_file}.bak")
          after = File.read(@config_file)
          Diffy::Diff.new(before, after, context: 3).to_s(type)
        end

        def show_diff
          return if @quiet || !changed?
          puts 'You ssh host configuration changed: '
          puts '--------------- DIFF ---------------'
          puts diff
          puts '--------------- /DIFF --------------'
          puts 'You can revert these changes by running "fulmar revert:ssh_config"'
        end

        def add_hosts
          backup_file
          @config.hosts.values.each do |data|
            unless config_valid?(data)
              puts "Skipping #{data[:hostname]}, config not sufficient." if @config[:debug]
              next
            end
            edit_host(data[:hostname], data[:ssh_config])
          end
          show_diff
        end

        def remove_known_host(hostname)
          input_file = File.open(@known_hosts_file, 'r')
          output_file = File.open(@known_hosts_file + '.temp', 'w')
          while (line = input_file.gets)
            output_file.puts(line) unless /^\[?#{hostname.gsub('.', '\\.')}(?:\]:\d+)?[ ,]/.match(line)
          end
          input_file.close
          output_file.close
          FileUtils.mv(@known_hosts_file + '.temp', @known_hosts_file)
        end

        def edit_host(hostname, ssh_config)
          data = read_file
          new_data = block_before(data.clone, hostname) +
                     host_entry(hostname, ssh_config) +
                     block_after(data, hostname)

          File.open(@config_file, 'w') do |file|
            file.puts new_data.join("\n")
          end
        end

        # Parses the users ssh config for an existing hostname
        def host_exists?(hostname)
          config_file = File.open(@config_file, 'r')
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
          config_file = File.open(@config_file, 'a')

          unless ssh_config[:IdentityFile].blank? or ssh_config[:IdentityFile][0, 1] == '/'
            ssh_config[:IdentityFile] = @config.base_path + '/' + ssh_config[:IdentityFile]
          end

          config_file.puts host_entry(hostname, ssh_config)

          config_file.close
        end

        def backup_file
          backup_filename = "#{@config_file}.bak"
          FileUtils.cp @config_file, backup_filename
        end

        protected

        def host_entry(hostname, ssh_config = {})
          unless ssh_config[:IdentityFile].blank? or ssh_config[:IdentityFile][0, 1] == '/'
            ssh_config[:IdentityFile] = @config.base_path + '/' + ssh_config[:IdentityFile]
          end

          entry = [
            '', # Add some space between this and the second last entry
            "Host #{hostname}"
          ]
          ssh_config.keys.each { |key| entry << "    #{key} #{escape_value(key, ssh_config[key])}" }
          entry << ''
          entry
        end

        def escape_value(key, value)
          value = value.to_s
          value = "\"#{value.gsub('"', '\\"')}\"" if value.include?(' ') && key.to_s != 'ProxyCommand'
          value
        end

        def read_file
          config_file_data = []
          File.open(@config_file, 'r') do |file|
            until file.eof?
              config_file_data << file.gets.chomp
            end
          end
          config_file_data
        end

        def config_valid?(host_config)
          (!host_config[:hostname].blank? && !host_config[:ssh_config].nil?)
        end

        def remove_trailing_newlines(data)
          while !data.empty? && data.last.strip.empty?
            data.pop
          end
          data
        end

        def block_before(data, hostname)
          cache = []
          before = []
          data.each do |line|
            if line.strip[0] == '#'
              cache << line
            else
              if /^Host\s#{hostname}$/.match line.strip
                return remove_trailing_newlines(before)
              end
              before += cache
              cache = []
              before << line
            end
          end
          remove_trailing_newlines(before)
        end

        def block_after(data, hostname)
          data = data.drop_while { |i| !/^Host\s#{hostname}$/.match(i.strip) }
          return [] if data.empty?
          data.shift

          after = []
          cache = []
          write = false
          data.each do |line|
            if line.strip[0] == '#'
              cache << line
            else
              if /^Host\s/.match line.strip
                write = true
              end
              if write
                after += cache
                after << line
              end
              cache = []
            end
          end
          remove_trailing_newlines(after)
        end
      end
    end
  end
end
