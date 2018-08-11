require 'test_helper'

class TeamTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  test "team has_many players" do
    assert_equal 12, teams(:test_utd).players.count
    assert_equal 11, teams(:test_utd).player_positions.size
    assert_equal 11, teams(:test_utd).player_positions_can_play.size
    players(:amy).update(injury: 1)
    assert_equal 11, teams(:test_utd).player_positions.size
    assert_equal 10, teams(:test_utd).player_positions_can_play.size
  end
end
