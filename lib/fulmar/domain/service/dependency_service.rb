require 'fulmar/shell'

module Fulmar
  module Domain
    module Service
      # Manages dependencies to subrepositories
      class DependencyService
        LOCK_FILE = 'Fulmar/dependencies.lock'

        def initialize(config)
          @config = config
        end

        def checkout(env = @config.environment)
          shell = Fulmar::Shell.new(@config[:local_path])

          read_lock_file

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

            checkout_repo(data)
          end

          # Update. This is not necessary after the initial checkout but
          # ensures the repo is up-to-date if it was already cloned
          # update(env)
        end

        # Updates all dependencies according to the dependency config and update the lock file
        def update(env = @config.environment)
          @config.dependencies(env).each_pair do |_key, data|
            next unless data[:type].blank? || data[:type] == 'git'

            handle_uncommitted_changes(data[:path], data)

            # Pull
            git = Fulmar::Domain::Model::Git.new data[:path]
            unless git.pull
              fail "Cannot update repository #{data[:path]}. Please update manually."
            end

          end


        end

        protected

        def write_lock_file

        end

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

        def checkout_repo(dependency, remote = 'origin')
          git_path = dependency[:path]
          handle_uncommitted_changes(git_path, dependency)

          # Switch to the configured branch/tag/commit
          if local_branches(git_path).include? dependency[:ref]
            system "cd #{git_path} && git checkout -q #{dependency[:ref]}"
          elsif remote_branches(git_path).include? dependency[:ref]
            system("cd #{git_path} && git checkout -q -b #{dependency[:ref]} #{remote}/#{dependency[:ref]}")
          elsif `cd #{git_path} && git tag`.split("\n").include?(dependency[:ref])
            system "cd #{git_path} && git checkout -q refs/tags/#{dependency[:ref]}"
          elsif dependency[:ref].match(/^[a-zA-Z0-9]{40}$/)
            system "cd #{git_path} && git checkout -q #{dependency[:ref]}"
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
