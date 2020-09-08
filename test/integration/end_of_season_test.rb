# typed: false
require 'test_helper'
require 'date'

class EndOfSeasonTest < ActiveSupport::TestCase
  test "end of season handling" do
    assert (not SeasonHelper.is_end_of_season?)
    Game.where.not(status: 'Played').all.each do |g| g.update(status: 'Played') end
    assert SeasonHelper.is_end_of_season?
    assert_equal Date.new(2018, 7, 3), SeasonHelper.last_game_date
    assert_equal 1, SeasonHelper::current_season
    assert Game.where(season: 2).count == 0
    SeasonHelper.handle_end_of_season
    assert_equal 2, SeasonHelper::current_season
    assert Game.where(season: 2).count > 0
  end
end
