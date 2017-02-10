require 'fulmar/domain/service/helper/common_helper'
include Fulmar::Domain::Service::Helper::CommonHelper

Fulmar::Domain::Service::PluginService.instance.helpers.each do |helper|
  include helper
end