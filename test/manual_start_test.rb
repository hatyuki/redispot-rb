require 'test_helper'

class Test::ManualStartTest < Test::Unit::TestCase
  test 'manually start the redis-server' do
    redis  = nil
    server = Redispot::Server.new

    server.start do |connect_info|
      redis = Redis.new(connect_info)
      assert_equal('PONG', redis.ping)
    end

    assert_raise(Errno::ENOENT) { redis.ping }
  end
end
