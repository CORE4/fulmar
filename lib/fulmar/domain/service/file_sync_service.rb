
require 'fulmar/infrastructure/model/transfer/rsync'
require 'fulmar/infrastructure/model/transfer/rsync_with_versions'
require 'fulmar/infrastructure/model/transfer/tar'

module Fulmar
  # Creates the required transfer model from the configuration
  class FileSync
    def self.get_model(config)
      case config[:type]
      when 'rsync_with_versions'
        transfer_model = Fulmar::Infrastructure::Model::Transfer::RsyncWithVersions.new(config)
      when 'rsync'
        transfer_model = Fulmar::Infrastructure::Model::Transfer::Rsync.new(config)
      when 'tar'
        transfer_model = Fulmar::Infrastructure::Model::Transfer::Tar.new(config)
      else
        help = config[:type] == '' ? 'Add a "type: " field to your deployment yaml file. ' : ''
        transfer_model = nil
        fail "Transfer type '#{config[:type]}' is not valid. #{help}Valid values are: rsync, rsync_with_versions."
      end

      transfer_model
    end
  end
end
