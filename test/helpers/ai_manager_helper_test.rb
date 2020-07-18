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
    assert_equal 16, FormationPo.where(formation: team.formation).count
  end

  test "maybe_sell_player" do
    team = PopulateDbHelper.make_team(name: "Test team", player_spawn_quality: 5)
    assert_equal 0, TransferListing.count
    AiManagerHelper.maybe_sell_player(team)
    assert_equal 1, TransferListing.count
  end

  # test broken now AI places bids rather than spawning players
  #test "maybe_acquire_player" do
  #  team = PopulateDbHelper.make_team(name: "Test team", player_spawn_quality: 5)
  #  num_players = team.players.count
  #  AiManagerHelper.maybe_acquire_player(team)
  #  assert_equal num_players+1, team.players.count
  #end
end
