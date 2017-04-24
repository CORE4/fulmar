require 'pp'

namespace :test do
  task :config do
    require 'fulmar/domain/service/config_test_service'
    test_service = Fulmar::Domain::Service::ConfigTestService.new(config)
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
    config.each do |env, target, _data|
      config.environment = env
      config.target = target

      next if config[:hostname].blank?
      remote_shell.quiet = true
      remote_shell.strict = false

      info "Testing #{env}:#{target}..."

      message = "Cannot open remote shell to host '#{config[:hostname]}' (#{env}:#{target})"

      begin
        remote_shell.run('true') || error(message)
      rescue
        error(message)
      end
    end
    info "Feelin' fine." if error_count == 0
  end
end
