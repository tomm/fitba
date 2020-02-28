require 'test_helper'
require 'date'

class PlayerHelperTest < ActiveSupport::TestCase
  test "youth_team" do
    team = teams(:test_utd)
    num_players = Player.where(team: team).count
    new_player = SeasonHelper.spawn_youth_teamer(team)
    assert_equal num_players+1, Player.where(team: team).count
    skill = new_player.skill
    50.times {PlayerHelper.daily_develop_youth_players}
    new_player.reload
    assert new_player.skill > skill
  end

  test "team has_many players" do
    assert_equal 0, Message.count
    assert_equal 12, teams(:test_utd).players.where(injury: 0).count
    PlayerHelper.spawn_injury_on_team(teams(:test_utd).id)
    assert_equal 11, teams(:test_utd).players.where(injury: 0).count
    50.times do
      PlayerHelper.daily_cure_injury
    end
    assert_equal 12, teams(:test_utd).players.where(injury: 0).count
  end

  test "daily_maybe_change_player_form" do
    # crappy test. at least it runs the code ;)
    #assert_equal 0, Message.count
    PlayerHelper.daily_maybe_change_player_form
    # each user should receive a training player form evaluation message
    # XXX not anymore :)
    #assert_equal User.count, Message.count
  end
end
