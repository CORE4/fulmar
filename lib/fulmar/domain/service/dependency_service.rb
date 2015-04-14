require 'rugged'

module Fulmar
  module Domain
    module Service
      # Manages dependencies to subrepositories
      class DependencyService
        def initialize(config)
          @config = config
        end

        def setup(env = @config.environment)
          shell = Fulmar::Infrastructure::Service::ShellService.new(@config[:local_path])
          @config.dependencies(env).each_pair do |_key, data|
            next unless data[:type].blank? || data[:type] == 'git'
            shell.run "git clone #{data[:source]} #{data[:path]} -q"
          end
        end

        def update(env = @config.environment)
          @config.dependencies(env).each_pair do |_key, data|
            next unless data[:type].blank? || data[:type] == 'git'
            git = Rugged::Repository.new(data[:path])

            # Switch to the configured branch/tag/commit
            if git.branches.select { |b| b.name.split('/').last == data[:ref] }.any?
              checkout_branch(git, data[:ref])
            elsif git.tags.map(&:name).include?(data[:ref])
              git.checkout('refs/tags/'+data[:ref])
            elsif data[:ref].match(/^[a-zA-Z0-9]{40}$/) && git.exists?(data[:ref])
              git.checkout(data[:ref])
            else
              fail "Cannot find ref #{data[:ref]} in repo #{data[:path]}"
            end

            # Pull
            shell = Fulmar::Infrastructure::Service::ShellService.new @config[:local_path]+'/'+data[:path]
            unless shell.run 'git pull --rebase -q'
              fail "Cannot update repository #{data[:path]}. Please update manually."
            end
          end
        end

        protected

        def checkout_branch(git, branch)
          if git.branches.collect(&:name).include? branch
            git.checkout(branch)
          else
            new_branch = git.branches.create(branch.split('/').last, branch)
            git.checkout(new_branch)
          end
        end
      end
    end
  end
end
