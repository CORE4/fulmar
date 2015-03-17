
require 'fulmar/infrastructure/service/transfer/rsync'
require 'fulmar/infrastructure/service/transfer/rsync_with_versions'

module Fulmar
  # Creates the required transfer model from the configuration
  class FileSync
    def self.create_transfer(config)
      case config[:type]
      when 'rsync_with_versions'
        transfer_model = Fulmar::Infrastructure::Service::Transfer::RsyncWithVersions.new(config)
      when 'rsync'
        transfer_model = Fulmar::Infrastructure::Service::Transfer::Rsync.new(config)
      else
        help = config[:type] == '' ? 'Add a "type: " field to your deployment yaml file. ' : ''
        transfer_model = nil
        fail "Transfer type '#{config[:type]}' is not valid. #{help}Valid values are: rsync, rsync_with_versions."
      end

      transfer_model
    end
  end
end
