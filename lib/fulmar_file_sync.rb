
require 'transfer/rsync_with_versions'
require 'bundler'
require 'ruby_wings'

module Fulmar

  class FileSync

    DEFAULT_CONFIG = {
        debug: false,
        host: nil,
        user: '',
        password: '',
        remote_path: nil,
        local_path: '.',
        type: :rsync_with_versions
    }

    attr_accessor :config

    def initialize(config = [])
      self.config = config
    end

    def config=(config)
      @config = DEFAULT_CONFIG.deep_merge(config)

      case @config[:type]
        when :rsync_with_versions
          @deploy_service = Fulmar::Transfer::RsyncWithVersions.new(@config)
        else
          raise "Transfer type '#{@config[:type]}' is not valid."
      end

      if @deploy_service.config_valid?
        true
      else
        STDERR.puts 'Config not valid.'
        false
      end
    end

    def deploy
      @deploy_service.transfer
    end

  end
end