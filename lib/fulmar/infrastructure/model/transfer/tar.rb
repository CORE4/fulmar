
require 'fulmar/infrastructure/model/transfer/base'

module Fulmar
  module Infrastructure
    module Model
      module Transfer
        # Implements the rsync transfer
        class Tar < Base
          DEFAULT_CONFIG = {
            tar: {
              format: 'gz', # 'bz2'
              file_base: nil,
              # exclude: "*.bak",
              # filename: "site.tar.gz"
            }
          }

          def initialize(config)
            @config = DEFAULT_CONFIG.deep_merge(config)

            @config[:tar][:file_base] = File.basename(@config[:local_path]) if @config[:tar][:file_base].nil?

            super(@config)
          end

          def transfer
            prepare unless @prepared
            @local_shell.run tar_command
            filename
          end

          # Build the rsync command from the given options
          def tar_command
            "tar #{tar_command_options} '#{filename}' '#{config[:local_path]}'"
          end

          protected

          def filename
            return @config[:tar][:filename] unless @config[:tar][:filename].blank?
            @config[:tar][:file_base] + '_' + Time.now.strftime('%Y-%m-%d') + extension
          end

          def extension
            @config[:tar][:format].blank? ? '.tar' : '.tar.' + @config[:tar][:format]
          end

          # Assembles all rsync command line parameters from the configuration options
          def tar_command_options
            options = ['-c']
            options << '-j' if @config[:tar][:format] == 'bz2'
            options << '-z' if @config[:tar][:format] == 'gz'
            options << "--exclude #{@config[:tar][:exclude]}" if @config[:tar][:exclude]
            options << '-f'
            options.join(' ')
          end
        end
      end
    end
  end
end
