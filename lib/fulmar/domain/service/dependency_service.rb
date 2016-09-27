require 'fulmar/shell'

module Fulmar
  module Domain
    module Service
      # Manages dependencies to subrepositories
      class DependencyService
        def initialize(config)
          @config = config
        end

        def setup(env = @config.environment)
          shell = Fulmar::Shell.new(@config[:local_path])
          @config.dependencies(env).each_pair do |_key, data|
            next unless data[:type].blank? || data[:type] == 'git'
            shell.quiet = true

            if Dir.exist? "#{data[:path]}/.git"
              shell.run 'git fetch -q', in: data[:path]
            else
              shell.run "git clone #{data[:source]} #{data[:path]} -q"
              shell.last_error.each do |line|
                puts line unless line.include? 'already exists and is not an empty directory'
              end
            end

            checkout(data[:path], data)
          end
        end

        def update(env = @config.environment)
          @config.dependencies(env).each_pair do |_key, data|
            next unless data[:type].blank? || data[:type] == 'git'

            handle_uncommitted_changes(data[:path], data)

            # Pull
            shell = Fulmar::Shell.new data[:path]
            unless shell.run 'git pull --rebase -q'
              fail "Cannot update repository #{data[:path]}. Please update manually."
            end
          end
        end

        protected

        ##
        # Runs a defined update policy to avoid git conflicts
        def handle_uncommitted_changes(git_path, dependency)
          policy = dependency[:update_policy] || ''

          case policy
          when 'reset'
            reset(git_path)
          when -> (p) { p.nil? || p.empty? }
            puts 'No update policy configured' if @config[:debug]
          else
            puts "Unexpected update policy #{policy}"
          end
        end

        ##
        # Reset changes
        def reset(git_path)
          system("cd #{git_path}; git reset --hard")
        end

        def checkout(git_path, dependency, remote = 'origin')
          handle_uncommitted_changes(git, dependency)

          # Switch to the configured branch/tag/commit
          if local_branches.include? dependency[:ref]
            system "cd #{git_path} && git checkout #{dependency[:ref]}"
          elsif remote_branches.include? dependency[:ref]
            system("cd #{git_path} && git checkout -b #{dependency[:ref]} #{remote}/#{dependency[:ref]}")
          elsif `cd #{git_path} && git tag`.split("\n").include?(dependency[:ref])
            system "cd #{git_path} && git checkout refs/tags/#{dependency[:ref]}"
          elsif dependency[:ref].match(/^[a-zA-Z0-9]{40}$/)
            system "cd #{git_path} && git checkout #{dependency[:ref]}"
          else
            fail "Cannot find ref #{dependency[:ref]} in repo #{dependency[:path]}"
          end
        end

        def local_branches(path)
          `cd #{path} && git branch`.split("\n").collect { |b| b.strip.gsub(/^\* /, '') }
        end

        def remote_branches(path)
          `cd #{path} && git branch -r`.split("\n").collect { |b| b.strip.split(' ').first.split('/').last }
        end
      end
    end
  end
end
