require 'test_helper'

class Test::NoServerTest < Test::Unit::TestCase
  test 'server is not created' do
    server = Redispot::Server.new
    server.instance_eval { @executable = 'does_not_exist' }

    assert_raise(RuntimeError) { server.start { } }
  end
end
