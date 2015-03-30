include Fulmar::Domain::Service::Helper::CommonHelper

if configuration.feature? :database
  require 'fulmar/service/helper/database_helper'
  include Fulmar::Domain::Service::Helper::DatabaseHelper
end

if configuration.feature? :flow
  require 'fulmar/service/helper/flow_helper'
  include Fulmar::Domain::Service::Helper::FlowHelper
end
