require 'test_helper'
require 'date'
require './app/end_of_season'

class EndOfSeasonTest < ActiveSupport::TestCase
  test "end of season handling" do
    assert (not EndOfSeason.is_end_of_season?)
    Game.where.not(status: 'Played').all.each do |g| g.update(status: 'Played') end
    assert EndOfSeason.is_end_of_season?
    assert_equal Date.new(2018, 7, 3), EndOfSeason.last_game_date
    assert_equal 1, DbHelper::SeasonHelper.current
    assert Game.where(season: 2).count == 0
    EndOfSeason.create_new_season
    assert_equal 2, DbHelper::SeasonHelper.current
    assert Game.where(season: 2).count > 0
  end
end
