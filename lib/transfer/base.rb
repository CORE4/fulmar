
require 'fulmar_shell'

module Fulmar

  module Transfer

    class Base

      DEFAULT_CONFIG = { debug: false }

      attr_accessor :config

      def initialize(config)
        @config = DEFAULT_CONFIG.merge(config)
        @prepared = false

        unless config_valid?
          raise 'Config invalid!'
        end

      end

      # Test the supplied config for required parameters
      def config_valid?
        required = [:host, :remote_path, :local_path]
        required.inject(true) {|prev, required_key| (prev and @config.include?(required_key) and not @config[required_key].empty?) }
      end

      def prepare
        @local_shell = Fulmar::Infrastructure::Service::ShellService.new @config[:local_path]
        @local_shell.debug = @config[:debug]
        @prepared = true
      end

      protected

      def ssh_user_and_host
        (@config[:user] and not @config[:user].empty?) ? @config[:user] + '@' + @config[:host] : @config[:host]
      end



    end

  end

end