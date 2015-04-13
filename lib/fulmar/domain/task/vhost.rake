if @config.any? { |data| data[:type] == 'vhost' }
  namespace :vhost do
    @config.each do |env, target, _data|
      desc "Create a vhost for #{env}"
      task :create do
        configuration.environment = env
        configuration.target      = target
        branch = git.current_branch
        if branch == 'master' || branch == 'release'
          STDERR.puts "Cannot deploy branch '#'"
        end
        configuration[:current_branch] = branch
        render_templates
        upload configuration[:vhost_template]
        sites_enabled_dir = configuration[:sites_enabled_dir] || '../sites_enabled'
        remote_shell.run [
                           "ln -s #{configuration[:vhost_template]} #{sites_enabled_dir}/#{configuration[:vhost_template]}",
                           "service #{configuration[:webserver] || 'nginx'} restart"
                         ]
      end
    end
  end
end
