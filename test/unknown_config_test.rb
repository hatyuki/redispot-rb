require 'test_helper'

class Test::UnknownConfigTest < Test::Unit::TestCase
  test 'server did not initialize' do
    assert_raise(RuntimeError) do
      Redispot::Server.new(config: { unknown_key: 'unknown_value' }).start
    end
  end
end
