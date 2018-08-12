require 'test_helper'

class TeamTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  test "team has_many players" do
    assert_equal 12, teams(:test_utd).players.count
    # one player hasn't been given a position...
    assert_equal 11, teams(:test_utd).player_positions.size
  end
end
