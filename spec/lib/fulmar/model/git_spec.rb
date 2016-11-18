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
end

