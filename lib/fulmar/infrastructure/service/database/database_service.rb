require 'mysql2'
require 'fulmar/infrastructure/service/tunnel_service'

module Fulmar
  module Infrastructure
    module Service
      module Database
        # Provides basic methods common to all database services
        class DatabaseService
          attr_accessor :client
          attr_reader :shell, :connected
          alias_method :connected?, :connected

          DEFAULT_CONFIG = {
            maria: {
              host: '127.0.0.1',
              port: 3306,
              user: 'root',
              password: '',
              encoding: 'utf8'
            }
          }

          def initialize(config)
            @config = config
            @config.merge DEFAULT_CONFIG
            @tunnel = nil
            @client = nil
            initialize_shell
            config_test
          end

          def connect
            options = compile_options

            unless local?
              tunnel.open
              options[:port] = tunnel.local_port
            end

            # Wait max 3 seconds for the tunnel to establish
            4.times do |i|
              break if try_connect(options, i)
            end

            @connected = true
          end

          def disconnect
            @connected = false
            @client.close
            @tunnel.close if @tunnel # using the variable directly avoids creating a tunnel instance when closing the database connection
          end

          def local?
            @config[:hostname] == 'localhost'
          end

          def tunnel
            @tunnel ||= Fulmar::Infrastructure::Service::TunnelService.new(@config.ssh_user_and_host, @config[:maria][:port], @config[:maria][:hostname])
          end

          # shortcut for DatabaseService.client.query
          def query(*arguments)
            @client.query(arguments)
          end

          def create(name)
            state_before = connected?
            connect unless connected?
            @client.query "CREATE DATABASE IF NOT EXISTS `#{name}`"
            disconnect unless state_before
          end

          def dump(filename = backup_filename)
            filename = "#{@config[:remote_path]}/#{filename}" unless filename[0, 1] == '/'

            diffable = @config[:maria][:diffable_dump] ? '--skip-comments --skip-extended-insert ' : ''

            @shell.run "mysqldump -h #{@config[:maria][:host]} -u #{@config[:maria][:user]} --password='#{@config[:maria][:password]}' " \
                       "#{@config[:maria][:database]} --single-transaction #{diffable}-r \"#{filename}\""

            filename
          end

          def load_dump(dump_file, database = @config[:maria][:database])
            @shell.run "mysql -h #{@config[:maria][:host]} -u #{@config[:maria][:user]} --password='#{@config[:maria][:password]}' " \
                       "-D #{database} < #{dump_file}"
          end

          def download_dump(filename = backup_filename)
            local_path = filename[0, 1] == '/' ? filename : @config[:local_path] + '/' + filename
            remote_path = dump
            copy = system("scp -Cq #{@config.ssh_user_and_host}:#{remote_path} #{local_path}")
            @shell.run "rm -f \"#{remote_path}\"" # delete temporary file
            if copy
              local_path
            else
              ''
            end
          end

          def clear
            clear_statements = <<-EOD.gsub(/^\s+\|/, '')
              |SET FOREIGN_KEY_CHECKS = 0;
              |SET GROUP_CONCAT_MAX_LEN=32768;
              |SET @tables = NULL;
              |SELECT GROUP_CONCAT('`', table_name, '`') INTO @tables
              |FROM information_schema.tables
              |WHERE table_schema = (SELECT DATABASE());
              |SELECT IFNULL(@tables,'dummy') INTO @tables;
              |
              |SET @tables = CONCAT('DROP TABLE IF EXISTS ', @tables);
              |PREPARE stmt FROM @tables;
              |EXECUTE stmt;
              |DEALLOCATE PREPARE stmt;
              |SET FOREIGN_KEY_CHECKS = 1;
            EOD
            @client.query clear_statements
          end

          protected

          def try_connect(options, i)
            @client = Mysql2::Client.new options
          rescue Mysql2::Error => e
            sleep 1 if i < 3
            raise e.message if i == 3
          end

          # Test configuration
          def config_test
            fail 'Configuration option "database" missing.' unless @config[:maria][:database]
          end

          # Builds the filename for a new database backup file
          # NOTE: The file might already exist, for example if this is run at the same
          # time from to different clients. I won't handle this as it is unlikely and
          # would result in more I/O
          def backup_filename
            "#{@config[:maria][:database]}_#{Time.now.strftime('%Y-%m-%dT%H%M%S')}.sql"
          end

          def initialize_shell
            path = local? ? @config[:local_path] : @config[:remote_path]
            @shell = Fulmar::Infrastructure::Service::ShellService.new(path , @config.ssh_user_and_host)
            @shell.debug = true if @config[:debug]
            @shell.strict = true
          end

          # Compiles a mysql config hash from valid options of the fulmar config
          def compile_options
            possible_options = [:host, :username, :password, :port, :encoding, :socket, :read_timeout, :write_timeout,
                                :connect_timeout, :reconnect, :local_infile, :secure_auth, :default_file, :default_group,
                                :init_command
                               ]
            options = { host: '127.0.0.1', username: @config[:maria][:user] }

            possible_options.each do |option|
              options[option] = @config[:maria][option] unless @config[:maria][option].nil?
            end

            options
          end
        end
      end
    end
  end
end
