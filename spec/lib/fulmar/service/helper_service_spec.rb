require 'fulmar/service/helper_service'

describe Fulmar::Service::HelperService, fakefs: true do
  BASE_PATH = '/srv/fulmar/service/helper_service_spec'

  def stub_test_files(base_path)
    4.times do |i|
      path = ''

      i.times do |n|
        path << "/folder_d#{(n + 1)}"
      end

      FileUtils.mkdir_p("#{base_path}#{path}")

      File.open("#{base_path}#{path}/file_d#{(i)}", 'w') do |f|
        f.write 'TEST CONTENT'
      end
    end
  end

  before(:each) do
    stub_test_files(BASE_PATH)
  end

  describe '#reverse_file_lookup' do
    it 'should return the path to the file' do
      file = described_class.reverse_file_lookup("#{BASE_PATH}/folder_d1/folder_d2/folder_d3", 'file_d1')
      expect(file).to eq("#{BASE_PATH}/folder_d1/file_d1")
    end

    it 'should return the path to the file' do
      file = described_class.reverse_file_lookup("#{BASE_PATH}/folder_d1/folder_d2", 'file_d2')
      expect(file).to eq("#{BASE_PATH}/folder_d1/folder_d2/file_d2")
    end

    ##
    # The file is located in a child directory of the given path
    it 'should return false' do
      file = described_class.reverse_file_lookup("#{BASE_PATH}/folder_d1/folder_d2/folder_d3", 'file_d4')
      expect(file).to eq(false)
    end

    ##
    # The file does not exist
    it 'should return false' do
      file = described_class.reverse_file_lookup("#{BASE_PATH}/folder_d1/folder_d2", 'file_d9')
      expect(file).to eq(false)
    end
  end
end
