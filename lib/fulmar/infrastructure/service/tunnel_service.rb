require 'socket'

module Fulmar
  module Infrastructure
    module Service
      # Opens an ssh tunnel to a remote host so other services can access mysql for example
      class TunnelService
        attr_reader :host, :remote_port, :local_port

        def initialize(host, port, remote_host = 'localhost')
          @host = host
          @remote_port = port
          @remote_host = remote_host.nil? ? 'localhost' : remote_host
          @local_port = 0
          @tunnel_pid = 0
        end

        def open
          @local_port = free_port
          @tunnel_pid = Process.spawn "ssh #{@host} -L #{@local_port}:#{@remote_host}:#{@remote_port} -N"
          sleep 1
        end

        def close
          Process.kill 'TERM', @tunnel_pid if @tunnel_pid > 0
          @local_port = 0
          @tunnel_pid = 0
        end

        def open?
          @tunnel_pid > 0
        end

        def free_port
          (60_000..61_000).each do |port|
            begin
              socket = TCPSocket.new('localhost', port)
              socket.close
            rescue Errno::ECONNREFUSED
              return port
            end
          end

          fail 'Cannot find an open local port'
        end
      end
    end
  end
end
