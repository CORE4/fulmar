require 'fulmar/shell'

module Fulmar
  module Domain
    module Model
      # Represents a git repository
      class Git
        attr_reader :path

        def initialize(path)
          @path = path
          @shell = Fulmar::Shell.new(path)
          fail "Path '#{path}' does not exists" unless File.exist? path
          fail "Path '#{path}' is not a valid git directory" unless File.exist? "#{path}/.git"
        end

        def current_commit_id
          @shell.run 'git rev-parse HEAD'
          @shell.last_output.first
        end

        def pull
          @shell.run 'git pull'
        end

        def checkout(ref)
          @shell.run "git checkout #{ref}"
        end

        def reset
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

        def uncommited_changes?
          @shell.run 'git status -s'
          !@shell.last_output.empty?
        end

        def unpushed_changes?
          @shell.run 'git status -b -s'
          !@shell.last_output.empty?
        end
      end
    end
  end
end
