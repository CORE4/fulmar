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
              encoding: 'utf8',
              ignore_tables: []
            }
          }

          def initialize(config)
            @config = config
            @config.merge DEFAULT_CONFIG
            initialize_shell
            config_test
          end

          def local?
            @config[:hostname] == 'localhost'
          end

          def command(binary)
            command = binary
            command << " -h #{@config[:maria][:host]}" unless @config[:maria][:host].blank?
            command << " -u #{@config[:maria][:user]}" unless @config[:maria][:user].blank?
            command << " --password='#{@config[:maria][:password]}'" unless @config[:maria][:password].blank?
            command
          end

          def dump(filename = backup_filename)
            filename = "#{@config[:remote_path]}/#{filename}" unless filename[0, 1] == '/'

            @shell.run "#{command('mysqldump')} #{@config[:maria][:database]} --single-transaction #{diffable} #{ignore_tables} -r \"#{filename}\""

            filename
          end

          def load_dump(dump_file, database = @config[:maria][:database])
            @shell.run "#{command('mysql')} -D #{database} < #{dump_file}"
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

          protected

          # Return mysql command line options to ignore specific tables
          def ignore_tables
            @config[:maria][:ignore_tables] = [*@config[:maria][:ignore_tables]]
            @config[:maria][:ignore_tables].map do |table|
              "--ignore-table=#{@config[:maria][:database]}.#{table}"
            end.join(' ')
          end

          # Return the mysql configuration options to make a dump diffable
          def diffable
            @config[:maria][:diffable_dump] ? '--skip-comments --skip-extended-insert ' : ''
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
