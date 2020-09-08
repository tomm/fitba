# typed: false
require 'test_helper'

class PlayerTest < ActiveSupport::TestCase
  test "happy_birthday" do
    p = Player.random(9)
    p.age = 30
    p.happy_birthday
    assert_equal 31, p.age
    15.times do
      p.happy_birthday
    end

    Player::ALL_SKILLS.each do |skill|
      assert_equal 1, p.method(skill).call()
    end
  end
end
