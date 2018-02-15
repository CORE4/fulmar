
require 'fulmar/infrastructure/model/transfer/rsync'
require 'fulmar/infrastructure/model/transfer/rsync_with_versions'
require 'fulmar/infrastructure/model/transfer/tar'

module Fulmar
  # Creates the required transfer model from the configuration
  class FileSync
    def self.get_class(config)
      case config[:type]
      when 'rsync_with_versions'
        transfer_class = Fulmar::Infrastructure::Model::Transfer::RsyncWithVersions
      when 'rsync'
        transfer_class = Fulmar::Infrastructure::Model::Transfer::Rsync
      when 'tar'
        transfer_class = Fulmar::Infrastructure::Model::Transfer::Tar
      else
        help = config[:type] == '' ? 'Add a "type: " field to your deployment yaml file. ' : ''
        raise "Transfer type '#{config[:type]}' is not valid. #{help}Valid values are: rsync, rsync_with_versions."
      end

      transfer_class
    end
  end
end
