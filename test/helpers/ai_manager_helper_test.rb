require 'test_helper'
require 'date'

class EndOfSeasonTest < ActiveSupport::TestCase
  test "pick_team_formation" do
    team = teams(:test_athletico)
    # has no players
    assert_equal 0, FormationPo.where(formation: team.formation).count
    AiManagerHelper.pick_team_formation(team)
    assert_equal 0, FormationPo.where(formation: team.formation).count

    team = teams(:test_city)
    # has no players
    FormationPo.where(formation: team.formation).delete_all
    assert_equal 0, FormationPo.where(formation: team.formation).count
    AiManagerHelper.pick_team_formation(team)
    assert_equal 11, FormationPo.where(formation: team.formation).count
  end

  test "maybe_sell_player" do
    #team = PopulateDbHelper.make_team
    #puts "Team has #{team.players.size} players!"
    #AiManagerHelper.maybe_sell_player(team)
  end
end
