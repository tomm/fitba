require 'test_helper'
require 'date'

class InjuryHelperTest < ActiveSupport::TestCase
  test "team has_many players" do
    assert_equal 0, Message.count
    assert_equal 12, teams(:test_utd).players.where(injury: 0).count
    InjuryHelper.spawn_injury_on(teams(:test_utd).id)
    # should have generated a message about the player's injury
    assert_equal 1, Message.count
    assert_equal 11, teams(:test_utd).players.where(injury: 0).count
    50.times do
      InjuryHelper.daily_cure_injury
    end
    # should have generated a message about the player's recovery
    assert_equal 2, Message.count
    assert_equal 12, teams(:test_utd).players.where(injury: 0).count
  end
end
