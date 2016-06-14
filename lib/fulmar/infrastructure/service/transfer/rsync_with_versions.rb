
require 'fulmar/infrastructure/service/transfer/base'
require 'time'
require 'ruby_wings'

module Fulmar
  module Infrastructure
    module Service
      module Transfer
        # Provides syncing with versioning on the server
        #
        # Every deployment results in a new directory in the releases directory with the deployment time as
        # the folder name. A symlink 'current' points to this new directory after publish() is called.
        class RsyncWithVersions < Base
          TIME_FOLDER = '%Y-%m-%d_%H%M%S'
          TIME_READABLE = '%Y-%m-%d %H:%M:%S'

          DEFAULT_CONFIG = {
            temp_dir: 'temp',
            releases_dir: 'releases',
            shared_dir: 'shared',
            rsync: {
              exclude: nil,
              exclude_file: nil,
              chown: nil,
              chmod: nil,
              delete: true
            },
            symlinks: {},
            limit_releases: 5,
            shared: []
          }

          # @param [Fulmar::Domain::Service::ConfigurationService] config
          def initialize(config)
            @config = config
            @config.merge(DEFAULT_CONFIG)
            super(@config)

            if @config[:rsync][:exclude_file].blank? && File.exist?(@config[:local_path] + '/.rsyncignore')
              @config[:rsync][:exclude_file] = @config[:local_path] + '/.rsyncignore'
            end

            @release_time = Time.now
          end

          # Ensures all needed services are set up
          def prepare
            super
            @remote_shell = Fulmar::Infrastructure::Service::ShellService.new @config[:remote_path], @config.ssh_user_and_host
            @remote_shell.debug = @config[:debug]
          end

          # Copy the files via rsync to the release_path on the remote machine
          # @return [true, false] success
          def transfer
            prepare unless @prepared

            create_paths && @local_shell.run(rsync_command) && copy_temp_to_release && add_shared
          end

          # Publishes the current release (i.e. sets the 'current' symlink)
          # @return [true, false] success
          def publish
            prepare unless @prepared
            create_symlink
          end

          # Gets the currently generated absolute release path
          # @return [String] the release directory
          def release_path
            @config[:remote_path] + '/' + release_dir
          end

          # Gets the currently generated release directory
          # @return [String] the release directory
          def release_dir
            @config[:releases_dir] + '/' + @release_time.strftime('%Y-%m-%d_%H%M%S')
          end

          # Lists the existing releases on the remote machine
          # @param plain [boolean] if the list should be plain directory names or more readable time strings with a star for the current release
          # @return [Array] list of dirs or dates/times
          def list_releases(plain = true)
            prepare unless @prepared
            @remote_shell.run "ls -1 '#{@config[:releases_dir]}'"
            list = @remote_shell.last_output.select { |dir| dir.match(/^\d{4}-\d{2}-\d{2}_\d{6}/) }
            return list if plain

            current = current_release
            list.collect do |item|
              Time.strptime(item, TIME_FOLDER).strftime(TIME_READABLE) + (item == current ? ' *' : '')
            end
          end

          # Cleans up old releases limited by :limit_releases
          # @return [true, false] success
          def cleanup
            limit = @config[:limit_releases].to_i
            return true unless limit > 0
            releases = list_releases.sort
            return true if releases.length <= limit
            obsolete_dirs = releases[0, releases.length - limit].collect { |dir| "\"#{@config[:releases_dir]}/#{dir}\"" }
            @remote_shell.run "rm -fr #{obsolete_dirs.join(' ')}"
          end

          # Return the release at which the "current" symlinks points at
          def current_release
            prepare unless @prepared
            @remote_shell.run 'readlink -f current'
            @remote_shell.last_output.first.split('/').last
          end

          # Reverts to a given release
          #
          # @params release [String] the release folder or time string (which is found in the output list)
          # @return [true, false] success
          def revert(release = last_release)
            prepare unless @prepared

            return false if release.nil?

            # Convenience: Allow more readable version string from output
            if release.match(/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
              release = Time.strptime(item, TIME_READABLE).strftime(TIME_FOLDER)
            end

            create_symlink release
          end

          protected

          def last_release
            list = list_releases
            current = current_release
            current_index = list.index(current)
            (current_index.nil? || current_index == 0) ? nil : list[current_index - 1]
          end

          # Creates all necessary paths on the remote machine
          # @return [true, false] success
          def create_paths
            paths = [@config[:releases_dir], @config[:temp_dir], @config[:shared_dir]]
            @remote_shell.run paths.collect { |path| "mkdir -p '#{@config[:remote_path]}/#{path}'" }
          end

          # Builds the rsync command
          # @return [String] the command
          def rsync_command
            options = ['-rl']
            options << rsync_excludes if rsync_excludes
            options << "--exclude-from='#{@config[:rsync][:exclude_file]}'" if @config[:rsync][:exclude_file]
            options << "--chown='#{@config[:rsync][:chown]}'" if @config[:rsync][:chown]
            options << "--chmod='#{@config[:rsync][:chmod]}'" if @config[:rsync][:chmod]
            options << '--delete' if @config[:rsync][:delete]

            "rsync #{options.join(' ')} '#{@config[:local_path]}/' '#{@config.ssh_user_and_host}:#{@config[:remote_path]}/#{@config[:temp_dir]}'"
          end

          # Copies the data from the sync temp to the actual release directory
          # @return [true, false] success
          def copy_temp_to_release
            @remote_shell.run "cp -pr #{@config[:temp_dir]} #{release_dir}"
          end

          # Set the symlink to the given release or the return value of release_dir() otherwise
          #
          # @params release [String] the release folder
          # @return [true, false] success
          def create_symlink(release = nil)
            @remote_shell.run [
              "ln -s #{release ? @config[:releases_dir] + '/' + release : release_dir} current_new",
              "mv -T #{@config[:remote_path]}/current_new #{@config[:remote_path]}/current"
            ]
          end

          # Creates symlinks into the shared folder
          #
          # An entry in :shared might be "data/resources/images", so we first need to create
          # the directory "data/resources" in the release dir and afterwards create the link
          # @return [true, false] success
          def add_shared
            commands = [] # Collect all remote commands first, then execute them in one step to avoid reconnecting very often
            @config[:shared].each do |dir|
              commands << "mkdir -p \"#{release_dir}/#{dir}\""

              unless remote_dir_exists?("#{@config[:shared_dir]}/#{dir}")
                commands << "mkdir -p \"#{@config[:shared_dir]}/#{File.dirname(dir)}\""
                commands << "cp -pr \"#{release_dir}/#{dir}\" \"#{@config[:shared_dir]}/#{File.dirname(dir)}\""
              end

              commands << "rm -fr \"#{release_dir}/#{dir}\""
              commands << "mkdir -p \"#{release_dir}/#{File.dirname(dir)}\""
              commands << "ln -s \"#{@config[:remote_path]}/#{@config[:shared_dir]}/#{dir}\" \"#{release_dir}/#{dir}\""
            end

            @remote_shell.run commands if commands.length > 0
          end

          def remote_dir_exists?(dir)
            @remote_shell.run "test -d \"#{dir}\""
          end
        end
      end
    end
  end
end
