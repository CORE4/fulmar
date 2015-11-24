#require 'fulmar/service/helper_service'
#require 'fulmar/domain/model/configuration'

require 'fulmar/domain/service/plugin_service'

module Fulmar
  module Plugin
    module Maria
      class Database
      end
    end
  end
end

describe Fulmar::Domain::Service::PluginService do
  before :each do
    @plugin_service = Fulmar::Domain::Service::PluginService.instance
  end

  describe '#classname' do
    it 'returns a module' do
      expect(@plugin_service.classname :maria).to eql(Fulmar::Plugin::Maria)
    end

    it 'returns a class' do
      expect(@plugin_service.classname(:maria, :database)).to eql(Fulmar::Plugin::Maria::Database)
    end
  end
end