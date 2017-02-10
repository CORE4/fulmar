require 'fulmar/domain/model/git'
require 'fulmar/domain/model/configuration'
#require 'active_support'
require 'pp'
require 'helpers/mock_shell'
require 'fakefs/spec_helpers'

TEST_GIT_PATH = '/tmp/testgit'.freeze

module Fulmar
  module Domain
    module Model
      # Add shell setter
      class Git
        def shell=(shell)
          @shell = shell
        end
      end
    end
  end
end

describe Fulmar::Domain::Model::Git do
  before :all do
    include FakeFS::SpecHelpers
    FileUtils.mkdir_p "#{TEST_GIT_PATH}/.git"
    FileUtils.touch "#{TEST_GIT_PATH}/.git/config"
  end

  before :each do
    @git = Fulmar::Domain::Model::Git.new(TEST_GIT_PATH)
    @shell = Fulmar::MockShell.new(TEST_GIT_PATH)
    @git.shell = @shell
  end

  describe '#initialize' do
    it 'takes a path valid' do
      expect(@git).not_to be_nil
    end

    it 'fails on a non-existing directory' do
      expect { Fulmar::Domain::Model::Git.new('/does/not/exist') }.to raise_error(RuntimeError)
    end

    it 'fails on a non-git directory' do
      expect { Fulmar::Domain::Model::Git.new('/') }.to raise_error(RuntimeError)
    end
  end

  describe '#current_commit_hash' do
    it 'calls git' do
      output = @git.current_commit_id
      expect(@shell.last_commands.first).to eq('git rev-parse HEAD')
      expect(output).to eq(@shell.last_output.first)
    end
  end

  describe '#pull' do
    it 'calls git' do
      @git.pull
      expect(@shell.last_commands.last[0, 8]).to eq('git pull')
    end
  end

  describe '#checkout' do
    it 'calls git with explicit ref given' do
      @git.checkout('master')
      expect(@shell.last_commands.last[0, 12]).to eq('git checkout')
      expect(@shell.last_commands.last).to include('master')
    end
  end

  describe '#reset' do
    it 'calls git' do
      @git.reset
      expect(@shell.last_commands.last[0, 16]).to eq('git reset --hard')
    end
  end

  describe '#remote_branches' do
    it 'calls git' do
      @git.remote_branches
      expect(@shell.last_commands.last).to eq('git branch -r')
    end

    it 'returns the remote branches' do
      @shell.last_output = [
        '  origin/2.0',
        '  origin/HEAD -> origin/master',
        '  origin/f4780_update_policies',
        '  origin/master'
      ]
      expect(@git.remote_branches).to eq(%w(2.0 HEAD f4780_update_policies master))
    end
  end

  describe '#local_branches' do
    it 'calls git' do
      @git.local_branches
      expect(@shell.last_commands.last).to eq('git branch')
    end

    it 'returns the local branches' do
      @shell.last_output = ['* 2.0', '  master']
      expect(@git.local_branches).to eq(%w(2.0 master))
    end
  end

  describe '#tags' do
    it 'calls git' do
      @git.tags
      expect(@shell.last_commands.last).to eq('git tag')
    end

    it 'returns the tag list' do
      output = %w(0.1.0 0.2.0 0.3.0 0.3.1 0.5.0)
      @shell.last_output = output
      expect(@git.tags).to eq(output)
    end
  end

  describe '#unpushed_changes?' do
    it 'returns false when everything is up-to-date' do
      @shell.last_output = []
      expect(@git.unpushed_changes?).to be false
      expect(@shell.last_commands.last).to include('git status')
      expect(@shell.last_commands.last).to include(' -b ')
    end

    it 'returns true when there are changes to push' do
      @shell.last_output = ['## master...origin/master [behind 1]']
      expect(@git.unpushed_changes?).to be true
    end
  end

  describe '#repo?' do
    it 'returns false on a non-existing dir' do
      repo_exists = Fulmar::Domain::Model::Git.repo?('/this/path/does hopefully/not exist')
      expect(repo_exists).to be false
    end

    it 'returns false on a non-git-dir' do
      repo_exists = Fulmar::Domain::Model::Git.repo?('/')
      expect(repo_exists).to be false
    end

    it 'returns true on a valid git dir' do
      repo_exists = Fulmar::Domain::Model::Git.repo?(@git.path)
      expect(repo_exists).to be true
    end

    it 'handles an invalid path' do
      repo_exists = Fulmar::Domain::Model::Git.repo?(nil)
      expect(repo_exists).to be false
    end
  end

  describe '#remotes' do
    it 'calls git' do
      @git.remotes
      expect(@shell.last_commands.last).to eq('git remote')
    end
  end

  describe '#has_remote?' do
    it 'checks all remotes' do
      @shell.last_output = %w(origin kayssun core4)
      found = @git.has_remote?('git@github.com:CORE4/fulmar.git')
      expect(@shell.last_commands.last).to eq('git remote get-url --all \'core4\'')
      expect(found).to be false
    end

    it 'finds an existing remote' do
      @shell.last_output = %w(origin kayssun core4)
      # this is a trick but I guess it will do (search for kayssun, so it will find something)
      # I can't modify the mock shell output according to the different commands
      found = @git.has_remote?('kayssun')
      expect(@shell.last_commands.last).to eq('git remote get-url --all \'origin\'')
      expect(found).to be true
    end
  end

  describe '#clean' do
    it 'returns false when the are changes' do
      @shell.last_output = [' M lib/fulmar/domain/model/git.rb', ' M spec/lib/fulmar/model/git_spec.rb']
      expect(@git.clean?).to be false
    end

    it 'returns true when the repo has no open changes' do
      @shell.last_output = []
      expect(@git.clean?).to be true
    end
  end

  describe '#fetch' do
    it 'calls git' do
      @git.fetch
      expect(@shell.last_commands.last).to eq('git fetch')
    end
  end
end

