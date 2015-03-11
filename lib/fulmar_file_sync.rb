
require 'transfer/rsync_with_versions'
require 'bundler'
require 'ruby_wings'

module Fulmar

  class FileSync

    def self.create_transfer(config)
      case config[:type]
        when 'rsync_with_versions'
          transfer_model = Fulmar::Transfer::RsyncWithVersions.new(config)
        when 'rsync'
          transfer_model = Fulmar::Transfer::Rsync.new(config)
        else
          help = ''
          help = 'Add a "type: " field to your deployment yaml file. ' if config[:type] == ''
          raise "Transfer type '#{config[:type]}' is not valid. #{help}Valid values are: rsync, rsync_with_versions."
      end

      transfer_model
    end

  end
end