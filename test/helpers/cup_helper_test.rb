# typed: false
require 'test_helper'
require 'date'

class PlayerHelperTest < ActiveSupport::TestCase
  test "cup_helper_fixtures" do
    cup = League.create(kind: "Cup", name: "Fitba Association Cup")
    CupHelper.update_cup(cup, 1)
    CupHelper.update_cup(cup, 1)
    Game.all.update(home_goals: 10, status: "Played")
    CupHelper.update_cup(cup, 1)
    CupHelper.update_cup(cup, 1)
    Game.all.update(home_goals: 10, status: "Played")
    CupHelper.update_cup(cup, 1)
    CupHelper.update_cup(cup, 1)
    Game.all.update(home_goals: 10, status: "Played")
    CupHelper.update_cup(cup, 1)
  end
end
