require 'fulmar/domain/service/helper/common_helper'
include Fulmar::Domain::Service::Helper::CommonHelper

if configuration.dependencies.any?
  require 'fulmar/domain/service/helper/dependencies_helper'
  include Fulmar::Domain::Service::Helper::DependenciesHelper
end

if configuration.feature?(:vhost)
  require 'fulmar/domain/task/optional/vhost'
end

Fulmar::Domain::Service::PluginService.instance.helpers.each do |helper|
  include helper
end