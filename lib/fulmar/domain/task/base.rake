include Fulmar::Domain::Service::Helper::CommonHelper

if configuration.has_feature? :database
  require 'fulmar/service/helper/database_helper'
  include Fulmar::Domain::Service::Helper::DatabaseHelper
end

if configuration.has_feature? :neos
  require 'fulmar/service/helper/neos_helper'
  include Fulmar::Domain::Service::Helper::NeosHelper
end