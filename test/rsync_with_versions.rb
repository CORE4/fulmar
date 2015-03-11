require 'minitest/autorun'
require 'transfer/rsync_with_versions'

class RsyncWithVersionsTest < MiniTest::Unit::TestCase

  def setup
    @transfer = Fulmar::Infrastructure::Service::Transfer::RsyncWithVersions.new({
                                          host: 'example.com',
                                          remote_dir: '/tmp',
                                          rsync: {
                                              exclude: 'foo'
                                          },
                                          type: :rsync_with_versions
                                      })
  end

  def test_release_dir_contains_current_date
    assert_match /\/#{Time.now.strftime('%Y-%m-%d')}_/, @transfer.release_dir
  end


end