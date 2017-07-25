require 'fulmar/infrastructure/service/ssh_config_service'

DEFAULT_CONFIG_FILE = "#{File.dirname(__FILE__)}/../../../fixtures/ssh_config/default_config.txt"
DEFAULT_KNOWN_HOSTS_FILE = "#{File.dirname(__FILE__)}/../../../fixtures/ssh_config/default_known_hosts.txt"
CONFIG_TEMP_FILE = "#{File.dirname(__FILE__)}/../../../fixtures/ssh_config/temp_config.txt"
KNOWN_HOSTS_TEMP_FILE = "#{File.dirname(__FILE__)}/../../../fixtures/ssh_config/temp_known_hosts.txt"

class MockProject
  attr_accessor :name, :description
end

class MockConfig
  def hosts
    []
  end

  def project
    MockProject.new
  end
end

def new_service(config_file = DEFAULT_CONFIG_FILE, known_hosts_file = DEFAULT_KNOWN_HOSTS_FILE)
  FileUtils.cp config_file, CONFIG_TEMP_FILE
  FileUtils.cp known_hosts_file, KNOWN_HOSTS_TEMP_FILE
  Fulmar::Infrastructure::Service::SSHConfigService.new(MockConfig.new, CONFIG_TEMP_FILE, KNOWN_HOSTS_TEMP_FILE)
end

describe Fulmar::Infrastructure::Service::SSHConfigService do
  describe '#edit_host' do
    it 'should create a backup file' do
      service = new_service
      service.edit_host('testhost', {'Hostname' => '123.example.com'})
      expect(File.exist?("#{CONFIG_TEMP_FILE}.bak")).to be true
    end

    it 'should add a host' do
      service = new_service
      service.edit_host('test_new', {'Hostname' => '123.example.com'})
      expect(File.read(CONFIG_TEMP_FILE)).to include('testhost')
      expect(File.read(CONFIG_TEMP_FILE)).to include('test_new')
    end

    it 'should replace an existing host' do
      service = new_service
      service.edit_host('testhost', {'Hostname' => '123.example.com'})
      expect(File.read(CONFIG_TEMP_FILE)).not_to include('1234')
    end

    it 'should keep a trailing comment above the edited host entry' do
      service = new_service
      service.edit_host('examplehost', {'Hostname' => '123.example.com'})
      expect(File.read(CONFIG_TEMP_FILE)).to include('trailing comment 4711')
    end

    it 'should keep replace the host comment above the edited host entry' do
      service = new_service
      service.edit_host('examplehost', {'Hostname' => '123.example.com'})
      expect(File.read(CONFIG_TEMP_FILE)).not_to include('host comment 0815')
    end

    it 'should keep the number of hosts when replacing one' do
      service = new_service
      service.edit_host('examplehost', {'Hostname' => '123.example.com'})
      before = File.read("#{CONFIG_TEMP_FILE}.bak").scan(/Host /).size
      expect(File.read(CONFIG_TEMP_FILE).scan(/Host /).size).to eql(before)
    end

    it 'should increase the number of hosts when adding one' do
      service = new_service
      service.edit_host('examplehost2', {'Hostname' => '123.example.com'})
      before = File.read("#{CONFIG_TEMP_FILE}.bak").scan(/Host /).size
      expect(File.read(CONFIG_TEMP_FILE).scan(/Host /).size).to eql(before + 1)
    end

    it 'should keep comments within unaffected host blocks' do
      service = new_service
      service.edit_host('testhost', {'Hostname' => '123.example.com'})
      expect(File.read(CONFIG_TEMP_FILE)).to include('whoop whoop whoop')
    end

    it 'should not add more new lines with every call' do
      service = new_service
      service.edit_host('testhost', {'Hostname' => '123.example.com'})
      service.edit_host('testhost', {'Hostname' => '123.example.com'})
      service.edit_host('testhost', {'Hostname' => '123.example.com'})
      service.edit_host('testhost', {'Hostname' => '123.example.com'})
      expect(File.read(CONFIG_TEMP_FILE)).not_to include("\n\n\n")
    end

    it 'should not change the file on a second run' do
      service = new_service
      service.edit_host('testhost', {'Hostname' => '123.example.com'})
      service.edit_host('testhost', {'Hostname' => '123.example.com'})
      before = File.read("#{CONFIG_TEMP_FILE}.bak")
      after = File.read(CONFIG_TEMP_FILE)
      expect(after).to eql(before)
    end
  end

  describe '#remove_trailing_newlines' do
    it 'should remove multiple newlines from an array' do
      service = new_service
      test_array = ['test', '', '', '']
      result = service.send(:remove_trailing_newlines, test_array)
      expect(result).to eql(['test'])
    end

    it 'should not touch non-empty lines' do
      service = new_service
      test_array = %w[test foo bar]
      result = service.send(:remove_trailing_newlines, test_array)
      expect(result).to eql(test_array)
    end
  end
end
