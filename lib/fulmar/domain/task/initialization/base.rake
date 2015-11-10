require 'fulmar/domain/service/helper/common_helper'
include Fulmar::Domain::Service::Helper::CommonHelper

if configuration.feature? :database
  require 'fulmar/domain/service/helper/database_helper'
  include Fulmar::Domain::Service::Helper::DatabaseHelper
end

if configuration.feature? :flow
  require 'fulmar/domain/service/helper/flow_helper'
  include Fulmar::Domain::Service::Helper::FlowHelper
end

if configuration.dependencies.any?
  require 'fulmar/domain/service/helper/dependencies_helper'
  include Fulmar::Domain::Service::Helper::DependenciesHelper
end

if configuration.feature?(:vhost)
  require 'fulmar/domain/task/optional/vhost'
end
