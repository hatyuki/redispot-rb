require 'test_helper'

class Test::WorkingDirTest < Test::Unit::TestCase
  test 'basic' do
    dir = Redispot::WorkingDirectory.new
    assert(Dir.exist?(dir.to_s))

    dir.delete
    assert(!Dir.exist?(dir.to_s))
  end
end
