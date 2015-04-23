require 'pp'

task :configtest do
  require 'fulmar/domain/service/config_test_service'
  test_service = Fulmar::Domain::Service::ConfigTestService.new(configuration)
  results = test_service.run

  results.each do |report|
    case report[:severity]
    when :warning
      warning report[:message]
    when :error
      error report[:message]
    else
      info report[:message]
    end
  end
end