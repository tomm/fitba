require 'test_helper'
require 'date'

class PlayerHelperTest < ActiveSupport::TestCase
  test "team has_many players" do
    assert_equal 0, Message.count
    assert_equal 12, teams(:test_utd).players.where(injury: 0).count
    PlayerHelper.spawn_injury_on(teams(:test_utd).id)
    # should have generated a message about the player's injury
    assert_equal 1, Message.count
    assert_equal 11, teams(:test_utd).players.where(injury: 0).count
    50.times do
      PlayerHelper.daily_cure_injury
    end
    # should have generated a message about the player's recovery
    assert_equal 2, Message.count
    assert_equal 12, teams(:test_utd).players.where(injury: 0).count
  end

  test "daily_maybe_change_player_form" do
    # crappy test. at least it runs the code ;)
    assert_equal 0, Message.count
    PlayerHelper.daily_maybe_change_player_form
    # each user should receive a training player form evaluation message
    assert_equal User.count, Message.count
  end
end
