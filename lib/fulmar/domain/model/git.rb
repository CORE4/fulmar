require 'fulmar/shell'

module Fulmar
  module Domain
    module Model
      # Represents a git repository
      class Git
        attr_reader :path, :readonly
        attr_accessor :update_policy

        def initialize(path, readonly = false)
          @path = path
          @shell = Fulmar::Shell.new(path)
          @readonly = readonly

          fail "Path '#{path}' does not exists" unless File.exist? path
          fail "Path '#{path}' is not a valid git directory" unless Git.repo? path
        end

        def clean?
          @shell.run 'git status -s'
          @shell.last_output.empty?
        end

        def current_commit_id
          @shell.run 'git rev-parse HEAD'
          @shell.last_output.first
        end

        def fetch
          return false if @readonly
          @shell.run 'git fetch'
        end

        def pull
          return false if @readonly
          @shell.run 'git pull'
        end

        def checkout(ref)
          return false if @readonly
          @shell.run "git checkout #{ref}"
        end

        def reset
          return false if @readonly
          @shell.run 'git reset --hard'
        end

        def local_branches
          @shell.run 'git branch'
          @shell.last_output.collect { |b| b.strip.gsub(/^\* /, '') }
        end

        def remote_branches
          @shell.run 'git branch -r'
          @shell.last_output.collect { |b| b.strip.split(' ').first.split('/').last }
        end

        def tags
          @shell.run 'git tag'
          @shell.last_output.collect { |b| b.strip }
        end

        def unpushed_changes?
          @shell.run 'git status -b -s'
          !@shell.last_output.empty?
        end

        def remotes
          @shell.run 'git remote'
          @shell.last_output.map(&:strip)
        end

        def has_remote?(uri)
          remotes.each do |remote|
            @shell.run "git remote get-url --all '#{remote}'"
            return true if @shell.last_output.select { |line| line.include?(uri) }.any?
          end
          false
        end

        def self.repo?(path)
          File.exist?("#{path}/.git/config")
        end

        def self.create(path, remote)
          if repo?(path)
            git_repo = Git.new(path)
            unless git_repo.has_remote?(remote)
              fail "Path '#{path}' does already exist and does not seem to have the same remote."
            end
            return git_repo
          end

          if remote.nil? || remote.empty?
            fail "Cannot create new repository in '#{path}', no remote given."
          end

          FileUtils.mkdir_p File.dirname(path)
          created = system "cd '#{File.dirname(path)}'; git clone -q '#{remote}' '#{File.basename(path)}'"
          fail "Cannot clone #{remote}" unless created
          Git.new(path)
        end
      end
    end
  end
end
