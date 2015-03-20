require 'git'

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

          @git = Git.open(@config[:local_path]) # :log => Logger.new(STDOUT)
        end

        def branches
          @git.branches
        end

        def feature_branches
          @git.branches.collect { |b| b.full }.select { |name| name.match(/^feature_/) }.sort
        end

        def preview_branches
          @git.branches.collect { |b| b.full }.select { |name| name.match(/^preview_/) }.sort
        end

        def checkout(branch_name = derive_branch_name)
          branches = @git.branches.local.find(branch_name)
          if branches.any?
            @git.checkout(branches.first)
          else
            branches = @git.branches.remote.find(branch_name)
            fail "Cannot find a valid branch, last search was for #{branch_name}" unless branches.any?
            @git.branch(branches.first)
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
