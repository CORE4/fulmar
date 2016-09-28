require 'fulmar/domain/service/helper/vhost_helper'
include Fulmar::Domain::Service::Helper::VhostHelper

VHOST_DEFAULT_CONFIG = {
  webserver: 'nginx',
  sites_enabled_dir: '../sites-enabled'
}

vhost_count = 0
config.each { |_env, _target, data| vhost_count += 1 unless data[:vhost_template].blank? }

namespace :vhost do
  config.each do |env, target, data|
    next if data[:vhost_template].blank?

    task_environment = vhost_count > 1 ? ":#{env}" : ''

    desc "Create a vhost for #{env}"
    task "create#{task_environment}" do
      config.environment = env
      config.target      = target
      config.merge(VHOST_DEFAULT_CONFIG)

      # Store remote_path for recovery
      remote_path = config[:remote_path]

      # Set some default variables:
      config[:sites_available_dir] ||= "/etc/#{config[:webserver]}/sites-available"
      config[:remote_path] = config[:sites_available_dir]
      config[:vhost_name] = vhost_name

      render_templates
      rendered_vhost_config = File.dirname(config[:local_path] + '/' + config[:vhost_template]) + \
                              '/' + File.basename(config[:vhost_template], '.erb')
      config_file_name = "#{File.dirname(rendered_vhost_config)}/auto_vhost_#{config[:vhost_name]}.conf"
      FileUtils.mv rendered_vhost_config, config_file_name
      upload config_file_name
      config_remote_path = config[:sites_available_dir] + '/' + File.basename(config_file_name)
      remote_shell.run [
        "rm -f #{config[:sites_enabled_dir]}/#{File.basename(config_file_name)}", # remove any existing link
        "ln -s #{config_remote_path} #{config[:sites_enabled_dir]}/#{File.basename(config_file_name)}",
        "service #{config[:webserver]} reload"
      ]

      FileUtils.rm config_file_name

      # recover remote path
      config[:remote_path] = remote_path
    end

    desc "List existing vhosts for #{env}"
    task "list#{task_environment}" do
      config.environment = env
      config.target      = target
      config.merge(VHOST_DEFAULT_CONFIG)

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
    task "delete#{task_environment}", [:name] do |_t, argv|
      config.environment = env
      config.target      = target
      config.merge(VHOST_DEFAULT_CONFIG)

      remote_shell.run [
        "rm auto_vhost_#{argv[:name]}.conf",
        "rm #{config[:sites_enabled_dir]}/auto_vhost_#{argv[:name]}.conf",
        "service #{config[:webserver] || 'nginx'} reload"
      ]
    end
  end
end
