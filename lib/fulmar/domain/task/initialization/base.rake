require 'fulmar/domain/service/helper/common_helper'
include Fulmar::Domain::Service::Helper::CommonHelper

if config.feature?(:vhost)
  require 'fulmar/domain/task/optional/vhost'
end

Fulmar::Domain::Service::PluginService.instance.helpers.each do |helper|
  include helper
end