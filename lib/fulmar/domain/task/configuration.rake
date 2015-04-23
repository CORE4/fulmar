require 'pp'

namespace :test do
  task :config do
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

  task :hosts do
    configuration.each do |env, target, _data|
      configuration.environment = env
      configuration.target = target

      next if configuration[:hostname].blank?
      remote_shell.quiet = true
      remote_shell.strict = false

      message = "Cannot open remote shell to host '#{configuration[:hostname]}' (#{env}:#{target})"

      begin
        unless remote_shell.run 'true'
          error message
        end
      rescue
        error message
      end
    end
  end
end
