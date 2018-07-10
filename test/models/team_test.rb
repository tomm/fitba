require 'test_helper'

class TeamTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  test "team has_many players" do
    assert_equal 12, teams(:test_utd).players.count
  end
end
