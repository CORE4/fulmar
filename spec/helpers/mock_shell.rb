module Fulmar
  class MockShell
    attr_accessor :path, :hostname, :last_commands, :quiet, :debug, :last_output

    def initialize(path, hostname = 'localhost')
      @path = path
      @hostname = hostname
      @last_commands = []
      @last_output = ['output']
    end

    def run(command)
      @last_commands += [*command]
    end
  end
end
