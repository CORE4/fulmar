require 'fulmar/service/helper_service'
require 'fulmar/domain/model/configuration'
require 'active_support'

FULMAR_TEST_CONFIG = {
  project: {
    name: 'Test data'
  },
  environments: {
    all: {
      local_path: 'Application',
      inherit_test: 'global'
    },
    staging: {
      all: {
        host: 'stagingserver',
        local_path: '/tmp',
        inherit_test: 'environment'
      },
      data: {
        relative_path: 'relative',
        absolute_path: '/absolute',
        remote_path: '/'
      },
      files: {
        inherit_test: 'local',
        local_path: '.',
        remote_path: 'tmp',
        hostname: 'localhost'
      }
    },
    live: {
      files: {
      },
      data: {
        local_path: 'Application',
        relative_path: 'SubApplication'
      }
    }
  },
  hosts: {
    liveserver: {
      hostname: 'liveserver',
      remote_path: '/liveserver'
    },
    stagingserver: {
      hostname: 'stagingserver',
      remote_path: '/stagingserver'
    }
  }

}

describe Fulmar::Domain::Model::Configuration do
  before :each do
    # Make a deep copy of the hash so we have a fresh copy for every test
    config_data = Marshal.load( Marshal.dump(FULMAR_TEST_CONFIG) )
    @config = Fulmar::Domain::Model::Configuration.new(config_data, '/tmp')
  end

  describe '#instantiation' do
    it 'should return a simple configuration option' do
      @config.environment = :staging
      @config.target = :files
      expect(@config[:inherit_test]).to eql('local')
    end

    it 'should return an inherited configuration option from the environment' do
      @config.environment = :staging
      @config.target = :data
      expect(@config[:inherit_test]).to eql('environment')
    end

    it 'should return an globally inherited configuration option' do
      @config.environment = :live
      @config.target = :files
      expect(@config[:inherit_test]).to eql('global')
    end
  end

  describe '#each' do
    it 'should iterate over all environments/targets do' do
      @all_targets = []
      FULMAR_TEST_CONFIG[:environments].keys.each do |env|
        next if env == :all
        FULMAR_TEST_CONFIG[:environments][env].keys.each do |target, _value|
          next if target == :all
          @all_targets << "#{env}/#{target}"
        end
      end
      @targets = []
      @config.each do |env, target, _data|
        @targets << "#{env}/#{target}"
      end
      expect(@targets).to eql(@all_targets)
    end
  end

  describe '#project' do
    it 'should return a new project' do
      expect(@config.project).to be_a Fulmar::Domain::Model::Project
    end
  end

  describe '#ready?' do
    it 'should return false if settings are missing' do
      expect(@config.ready?).to be false
      @config.environment = :staging
      expect(@config.ready?).to be false
      @config.environment = nil
      @config.target = :files
      expect(@config.ready?).to be false
    end

    it 'should return true with all settings given' do
      @config.environment = :staging
      @config.target = :files
      expect(@config.ready?).to be true
    end
  end

  describe '#merge_hosts' do
    it 'should merge the host configuration into the target' do
      @config.environment = :staging
      @config.target = :data
      expect(@config[:hostname]).to eql('stagingserver')
    end

    it 'should prefer the local configuration over the host configuration' do
      @config.environment = :staging
      @config.target = :data
      expect(@config[:remote_path]).to eql('/')
    end
  end

  describe '#merge' do
    it 'merges the given configuration into the current target' do
      default_config = { new_default_value: 'default' }
      @config.environment = :staging
      @config.target = :data
      @config.merge(default_config)
      expect(@config[:new_default_value]).to eql('default')
    end

    it 'prefers the explicit config over the default values' do
      default_config = { remote_path: '/default' }
      @config.environment = :staging
      @config.target = :data
      @config.merge(default_config)
      expect(@config[:remote_path]).to eql('/')
    end
  end

  describe '#path_expansion' do
    it 'keeps absolute paths' do
      @config.environment = :staging
      @config.target = :data
      expect(@config[:absolute_path]).to eql('/absolute')
    end

    it 'keeps remote paths' do
      @config.environment = :staging
      @config.target = :files
      expect(@config[:remote_path]).to eql('tmp')
    end

    it 'makes paths absolute' do
      @config.environment = :staging
      @config.target = :data
      expect(@config[:relative_path][0,1]).to eql('/')
    end

    it 'joins the path, local_path and a given third path' do
      @config.environment = :live
      @config.target = :data
      expect(@config[:relative_path]).to eql('/tmp/Application/SubApplication')
    end
  end
end
