
require 'transfer/base'
require 'pp'

module CORE4

  module Transfer

    class RsyncWithVersions < CORE4::Transfer::Base

      DEFAULT_CONFIG = {
          temp_dir: 'temp',
          releases_dir: 'releases',
          shared_dir: 'shared',
          rsync: {
              exclude: nil,
              exclude_file: '.rsyncignore',
              chown: nil,
              chmod: nil,
              delete: true
          },
          symlinks: {}
      }

      def initialize(config)
        @config = DEFAULT_CONFIG.deep_merge(config)
        super(@config)
        @release_time = Time.now

        # Remove trailing slashes
        @config[:local_path] = @config[:local_path].chomp('/') if @config[:local_path]
        @config[:remote_path] = @config[:remote_path].chomp('/') if @config[:remote_path]
      end

      def prepare
        super
        @remote_shell = CORE4::Service::Shell.new @config[:remote_path], ssh_user_and_host
        @remote_shell.debug = @config[:debug]
      end

      def transfer
        prepare unless @prepared

        create_paths
        @local_shell.run rsync_command
        copy_temp_to_release

        # Return release_path for other tasks to use later
        release_path
      end

      def publish
        create_symlink
      end

      def release_path
        @config[:remote_path] + '/' + release_dir
      end

      def release_dir
        @config[:releases_dir] + '/' + @release_time.strftime('%Y-%m-%d_%H%M%S')
      end

protected

      def create_paths
        paths = [@config[:releases_dir], @config[:temp_dir], @config[:shared_dir]]
        @remote_shell.run paths.collect{|path| "mkdir -p '#{@config[:remote_path]}/#{path}'"}
      end

      def rsync_command
        options = [ '-rl' ]
        options << "--exclude='#{@config[:rsync][:exclude]}'" if @config[:rsync][:exclude]
        options << "--exclude-from='#{@config[:rsync][:exclude_file]}'" if @config[:rsync][:exclude_file]
        options << "--chown='#{@config[:rsync][:chown]}'" if @config[:rsync][:chown]
        options << "--chmod='#{@config[:rsync][:chmod]}'" if @config[:rsync][:chmod]
        options << '--delete' if @config[:rsync][:delete]

        "rsync #{options.join(' ')} '#{@config[:local_path]}/' '#{ssh_user_and_host}:#{@config[:remote_path]}/#{@config[:temp_dir]}'"
      end

      def copy_temp_to_release
        @remote_shell.run "cp -r #{@config[:temp_dir]} #{release_dir}"
      end

      def create_symlink
        @remote_shell.run ["rm #{@config[:remote_path]}current", "ln -s #{release_path} current"]
      end

    end

  end

end