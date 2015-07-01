require 'test_helper'

class Test::UnknownConfigTest < Test::Unit::TestCase
  test 'block given' do
    assert_raise(RuntimeError) do
      Redispot::Server.new(config: { unknown_key: 'unknown_value' }) { }
    end
  end

  test 'no block given' do
    server = Redispot::Server.new(config: { unknown_key: 'unknown_value' })
    assert_raise(RuntimeError) { server.start { } }
  end
end
