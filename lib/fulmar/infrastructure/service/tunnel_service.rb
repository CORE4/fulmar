require 'socket'

module Fulmar
  module Infrastructure
    module Service
      class TunnelService
        attr_reader :host, :remote_port, :local_port

        def initialize(host, port, remote_host = 'localhost')
          @host = host
          @remote_port = port
          @remote_host = remote_host
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
          port = 60000
          begin
            1000.times do
              socket = TCPSocket.new('localhost', port)
              socket.close
              port += 1
            end
          rescue Errno::ECONNREFUSED
            return port
          end
          fail 'Cannot find an open local port'
          0
        end
      end
    end
  end
end