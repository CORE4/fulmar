require 'fulmar/domain/service/helper/vhost_helper'
include Fulmar::Domain::Service::Helper::VhostHelper

VHOST_DEFAULT_CONFIG = {
  webserver: 'nginx',
  sites_enabled_dir: '../sites-enabled',

}

vhost_count = 0
configuration.each { |_env, _target, data| vhost_count += 1 unless data[:vhost_template].blank? }

namespace :vhost do
  configuration.each do |env, target, data|
    next if data[:vhost_template].blank?

    desc "Create a vhost for #{env}"
    task (vhost_count > 1 ? "create:#{env}" : 'create') do
      configuration.environment = env
      configuration.target      = target
      configuration.merge(VHOST_DEFAULT_CONFIG)

      # Store remote_path for recovery
      remote_path = configuration[:remote_path]

      # Set some default variables:
      configuration[:sites_available_dir] ||= "/etc/#{configuration[:webserver]}/sites-available"
      configuration[:remote_path] = configuration[:sites_available_dir]
      configuration[:vhost_name] = vhost_name

      render_templates
      rendered_vhost_config = File.dirname(configuration[:local_path] + '/' + configuration[:vhost_template]) + \
                              '/' + File.basename(configuration[:vhost_template], '.erb')
      config_file_name = "#{File.dirname(rendered_vhost_config)}/auto_vhost_#{configuration[:vhost_name]}.conf"
      FileUtils.mv rendered_vhost_config, config_file_name
      upload config_file_name
      config_remote_path = configuration[:sites_available_dir] + '/' + File.basename(config_file_name)
      remote_shell.run [
                         "rm -f #{configuration[:sites_enabled_dir]}/#{File.basename(config_file_name)}", # remove any existing link
                         "ln -s #{config_remote_path} #{configuration[:sites_enabled_dir]}/#{File.basename(config_file_name)}",
                         "service #{configuration[:webserver]} reload"
                       ]

      # recover remote path
      configuration[:remote_path] = remote_path
    end

    desc "List existing vhosts for #{env}"
    task (vhost_count > 1 ? "list:#{env}" : 'list') do
      configuration.environment = env
      configuration.target      = target
      configuration.merge(VHOST_DEFAULT_CONFIG)

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
    task (vhost_count > 1 ? "delete:#{env}" : 'delete'), [:name] do |_t, argv|
      configuration.environment = env
      configuration.target      = target
      configuration.merge(VHOST_DEFAULT_CONFIG)

      remote_shell.run [
                         "rm auto_vhost_#{argv[:name]}.conf",
                         "rm #{configuration[:sites_enabled_dir]}/auto_vhost_#{argv[:name]}.conf",
                         "service #{configuration[:webserver] || 'nginx'} reload"
                       ]
    end
  end
end
