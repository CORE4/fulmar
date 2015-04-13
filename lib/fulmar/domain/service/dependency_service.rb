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
            shell.run "git clone #{data[:source]} #{data[:path]}"
          end
        end

        def update(env = @config.environment)
          @config.dependencies(env).each_pair do |_key, data|
            next unless data[:type].blank? || data[:type] == 'git'
            git = Rugged::Repository.new(data[:path])

            checkout_branch(git, data[:ref]) if git.branches.select { |b| b.name.split('/').last == data[:ref] }.any?
            git.checkout('refs/tags/'+data[:ref]) if git.tags.map(&:name).include?(data[:ref])
            git.checkout(data[:ref]) if git.exists? data[:ref]
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
