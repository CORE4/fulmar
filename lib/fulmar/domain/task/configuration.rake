require 'pp'

namespace :test do
  task :config do
    require 'fulmar/domain/service/config_test_service'
    test_service = Fulmar::Domain::Service::ConfigTestService.new(configuration)
    results = test_service.run

    results.each do |report|
      case report[:severity]
      when :warning
        warning "Warning: #{report[:message]}"
      when :error
        error "Error: #{report[:message]}"
      else
        info "Notice: #{report[:message]}"
      end
    end

    info "Feelin' fine." if results.empty?
  end

  task :hosts do
    error_count = 0
    configuration.each do |env, target, _data|
      configuration.environment = env
      configuration.target = target

      next if configuration[:hostname].blank?
      remote_shell.quiet = true
      remote_shell.strict = false

      message = "Cannot open remote shell to host '#{configuration[:hostname]}' (#{env}:#{target})"

      begin
        remote_shell.run 'true' || error(message)
      rescue
        error(message)
      end
    end
    info "Feelin' fine." if error_count == 0
  end
end
