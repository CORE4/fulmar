require 'rugged'

module Fulmar
  module Infrastructure
    module Service
      # Provides access to to the local git repository
      class GitService
        attr_accessor :git

        DEFAULT_CONFIG = {
          local_path: '.',
          git: {
            branch: nil
          }
        }

        def initialize(config)
          @config = config
          @config.merge(DEFAULT_CONFIG)

          unless @config[:git][:branch]
            @config[:git][:branch] = case config.environment
                                     when :preview
                                       'preview'
                                     when :live
                                       'release'
                                     else
                                       'master'
                                     end
          end

          @git = Rugged::Repository.new(@config[:local_path]) # :log => Logger.new(STDOUT)
        end

        def branches
          @git.branches.collect(&:name)
        end

        def feature_branches
          branches.select { |name| name.match(/^feature_/) }.sort
        end

        def preview_branches
          branches.select { |name| name.match(/^preview_/) }.sort
        end

        def current_hash
          @git.head.target_id
        end

        def current_branch
          @git.head.name.split('/').last
        end

        def checkout(branch_name = derive_branch_name)
          if branches.include?(branch_name)
            @git.checkout(branches.first)
          else
            branches = @git.branches.select { |b| b.name.match(/\/#{branch_name}$/) }
            fail "Cannot find a valid branch, last search was for #{branch_name}" unless branches.any?
            @git.checkout(branches.first)
          end
        end

        # The current preview branch is the alphabetically last preview branch
        def derive_branch_name
          @config[:git][:branch] == 'preview' ? preview_branches.last : @config[:git][:branch]
        end
      end
    end
  end
end
