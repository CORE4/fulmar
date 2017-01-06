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

  describe '#local_branches' do
    it 'calls git' do
      @shell.last_output = [
        '  origin/2.0',
        '  origin/HEAD -> origin/master',
        '  origin/f4780_update_policies',
        '  origin/master'
      ]
      branches = @git.remote_branches
      expect(@shell.last_commands.last).to eq('git branch -r')
      expect(branches).to eq(%w(2.0 HEAD f4780_update_policies master))
    end
  end

  describe '#local_branches' do
    it 'calls git' do
      @shell.last_output = ['* 2.0', '  master']
      branches = @git.local_branches
      expect(@shell.last_commands.last).to eq('git branch')
      expect(branches).to eq(%w(2.0 master))
    end
  end

  describe '#uncommited_changes?' do
    it 'returns false when everything is up-to-date' do
      expect(@git.uncommited_changes?).to be false
      expect(@shell.last_commands.last).to include('git status')
    end

    it 'returns true when a file is changed' do
      @shell.last_output = [' M Fulmarfile']
      expect(@git.uncommited_changes?).to be true
    end
  end

  describe '#uncommited_changes?' do
    it 'returns false when everything is up-to-date' do
      expect(@git.uncommited_changes?).to be false
      expect(@shell.last_commands.last).to include('git status')
      expect(@shell.last_commands.last).to include(' -b ')
    end

    it 'returns true when a file is changed' do
      @shell.last_output = ['## master...origin/master [behind 1]']
      expect(@git.uncommited_changes?).to be true
    end
  end
end

