require 'pp'

task :configtest do
  require 'fulmar/domain/service/config_test_service'
  test_service = Fulmar::Domain::Service::ConfigTestService.new(configuration)
  results = test_service.run

  pp results
end