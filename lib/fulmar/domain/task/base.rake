include Fulmar::Domain::Service::Helper::CommonHelper

if configuration.feature? :database
  require 'fulmar/service/helper/database_helper'
  include Fulmar::Domain::Service::Helper::DatabaseHelper
end

if configuration.feature? :flow
  require 'fulmar/service/helper/flow_helper'
  include Fulmar::Domain::Service::Helper::FlowHelper
end

if full_configuration[:dependencies].any?
  require 'fulmar/service/helper/dependencies_helper'
  include Fulmar::Domain::Service::Helper::DependenciesHelper
end

if configuration.feature?(:vhost) && configuration.any? { |data| !data[:vhost_template].blank? }
  require 'fulmar/domain/task/optional/vhost'
end