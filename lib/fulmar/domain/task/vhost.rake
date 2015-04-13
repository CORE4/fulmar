if configuration.any? { |data| data[:type] == 'vhost' }
  namespace :vhost do
    configuration.each do |env, target, data|
      next if data[:type] != 'vhost'

      desc "Create a vhost for #{env}"
      task :create do
        configuration.environment = env
        configuration.target      = target
        branch = git.current_branch
        match = branch.match(/f\d+_([a-zA-Z0-9]+)/)
        unless match
          STDERR.puts "Cannot deploy branch '#{branch}'"
          return
        end
        configuration[:current_branch] = branch
        configuration[:vhost_name] = match[1]
        render_templates
        upload configuration[:vhost_template]
        sites_enabled_dir = configuration[:sites_enabled_dir] || '../sites_enabled'
        remote_shell.run [
                           "ln -s #{configuration[:vhost_template]} #{sites_enabled_dir}/#{configuration[:vhost_template]}",
                           "service #{configuration[:webserver] || 'nginx'} reload"
                         ]
      end

      desc "List existing vhosts for #{env}"
      task :list do
        configuration.environment = env
        configuration.target      = target

        remote_shell.run 'ls -1'
        remote_shell.last_output.each do |line|
          match = line.match(/auto_vhost_(.*)\.conf/)
          if match
            name = match[1]
            puts "- #{name}, delete via 'fulmar vhost:delete[#{name}]'"
          end
        end
      end

      desc "Delete a vhost for #{env}"
      task :delete, [:name] do |_t, argv|
        configuration.environment = env
        configuration.target      = target

        remote_shell.run [
                           "rm auto_vhost_#{argv[:name]}.conf",
                           "service #{configuration[:webserver] || 'nginx'} reload"
                         ]
      end
    end
  end

end
