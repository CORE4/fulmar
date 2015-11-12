module Fulmar
  module Infrastructure
    module Service
      # Provides access to composer
      class CopyService
        # Copies a file to a remote server
        # @param [Fulmar::Infrastructure::Service::ShellService] shell
        # @param [String] local_file local filename, should be absolute
        # @param [String] remote_host SSH hostname
        # @param [String] remote_dir remote directory
        def self.upload(shell, local_file, remote_host, remote_dir)
          if shell.run "scp -Cr #{local_file} #{remote_host}:#{remote_dir.chomp('/')}/"
            "#{remote_dir.chomp('/')}/#{File.basename(local_file)}"
          end
        end

        # Downloads a file from a remote server
        # @param [Fulmar::Infrastructure::Service::ShellService] shell
        # @param [String] remote_host SSH hostname
        # @param [String] remote_file remote directory
        # @param [String] local_dir local filename, should be absolute
        def self.download(shell, remote_host, remote_file, local_dir = '.')
          if shell.run "scp -Cr #{remote_host}:#{remote_file} #{local_dir.chomp('/')}/"
            "#{local_dir.chomp('/')}/#{File.basename(remote_file)}"
          end
        end
      end
    end
  end
end
