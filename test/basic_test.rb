require 'test_helper'

class Test::BasicTest < Test::Unit::TestCase
  test 'bind UNIX socket' do
    redis = nil

    Redispot::Server.new do |connect_info|
      assert_match(/redis\.sock$/, connect_info[:path])
      assert_nil(connect_info[:url])

      redis = Redis.new(connect_info)
      assert_equal('PONG', redis.ping)
    end

    assert_raise(Errno::ENOENT) { redis.ping }
  end

  test 'bind TCP port' do
    redis  = nil
    config = { bind: '127.0.0.1', port: empty_port }

    Redispot::Server.new(config: config) do |connect_info|
      assert_equal("redis://127.0.0.1:#{config[:port]}/", connect_info[:url])
      assert_nil(connect_info[:path])

      redis = Redis.new(connect_info)
      assert_equal('PONG', redis.ping)
    end

    assert_raise(Redis::CannotConnectError) { redis.ping }
  end
end
