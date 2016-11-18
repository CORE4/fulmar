require 'fulmar/domain/service/dependency_service'
require 'fulmar/domain/model/configuration'
require 'active_support'
require 'pp'

describe Fulmar::Domain::Service::DependencyService do
  before :all do
    base_dir = `mktemp`.strip
    FileUtils.remove_entry_secure base_dir # because mktemp creates a file...
    @git_template_dir = "#{base_dir}/template"
    @test_dir = "#{base_dir}/test"
    FileUtils.mkdir_p(@git_template_dir)

    @content_file = 'testfile.txt'
    command_list = [
      "cd #{@git_template_dir}",
      'git init -q',
      "echo \"commit 1\" > #{@content_file}",
      "git add #{@content_file}",
      "git commit #{@content_file} -m 'Initial commit into master' -q",
      "echo \"commit 2\" > #{@content_file}",
      "git commit #{@content_file} -m 'Second commit into master' -q",
      "echo \"commit 3\" > #{@content_file}",
      'git branch preview', # create a preview branch which will be older
      "git commit #{@content_file} -m 'Third commit into master' -q",
      "echo \"commit 4\" > #{@content_file}",
      "git commit #{@content_file} -m 'Fourth commit into master' -q",
      'git checkout preview -q',
      "echo \"commit 5\" > #{@content_file}",
      "git commit #{@content_file} -m 'Third commit into preview' -q",
      'git checkout master -q'
    ].join(' && ')
    system command_list # run the commands, discard output

    @default_config = {
      environments: {
        test: { test: { local_path: File.dirname(@test_dir) } }
      },
      dependencies: {
        all: {
          testgit: {
            path: @test_dir,
            type: 'git',
            ref: 'master',
            source: @git_template_dir
          }
        }
      }
    }
  end

  before :each do
    shell = Fulmar::Shell.new(File.dirname(@test_dir))
    shell.run "git clone #{@git_template_dir} #{@test_dir}"
  end

  after :each do
    FileUtils.remove_entry_secure @test_dir
    fail 'Cannot remove directory' if File.exist? @test_dir
  end

  after :all do
    FileUtils.remove_entry_secure File.dirname(@test_dir)
  end

  def deep_copy(object)
    Marshal.load(Marshal.dump(object))
  end

  def new_config(data = @default_config)
    config = Fulmar::Domain::Model::Configuration.new(deep_copy(data))
    config.set :test, :test
    config
  end

  def file_content
    file = "#{@test_dir}/#{@content_file}"
    File.read(file).strip
  end

  describe '#setup' do
    it 'checks out the master branch' do
      @dependency_service = Fulmar::Domain::Service::DependencyService.new(new_config)
      FileUtils.remove_entry_secure @test_dir # this is a bit silly, I know :)
      @dependency_service.update
      expect(file_content).to eq('commit 4')
    end

    it 'checks if the local_path matches a dependency' do
      config = new_config
      config[:local_path] = @test_dir
      @dependency_service = Fulmar::Domain::Service::DependencyService.new(config)
      expect { @dependency_service.update }.to raise_error(RuntimeError)
    end

    it 'checks out the preview branch' do
      data = deep_copy(@default_config)
      data[:dependencies][:all][:testgit][:ref] = 'preview'
      FileUtils.remove_entry_secure @test_dir # this is a bit silly, I know :)
      @dependency_service = Fulmar::Domain::Service::DependencyService.new(new_config(data))
      @dependency_service.update
      expect(file_content).to eq('commit 5')
    end

    it 'updates during checkout' do
      @dependency_service = Fulmar::Domain::Service::DependencyService.new(new_config)
      shell = Fulmar::Shell.new(@test_dir)
      shell.run 'git reset --hard HEAD^1'
      @dependency_service.update
      expect(file_content).to eq('commit 4')
    end

    it 'creates a new lock file' do
      config = new_config
      @dependency_service = Fulmar::Domain::Service::DependencyService.new(config)
      expect(File.exist?(config.base_path + '/' + Fulmar::Domain::Service::DependencyService::LOCK_FILE)).to be false
      @dependency_service.update
      expect(File.exist?(config.base_path + '/' + Fulmar::Domain::Service::DependencyService::LOCK_FILE)).to be true
    end
  end


end
