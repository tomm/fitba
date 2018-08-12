require 'test_helper'

class GameTest < ActiveSupport::TestCase
  test "simulate" do
    # make goalkeeper injured, so we test logic of assigning a new one
    players(:amy).update(injury: 1)
    players(:nancy).update(injury: 1)
    game = games(:seven)
    assert_equal "Scheduled", game.status
    game.simulate(game.start - 10)
    assert_equal "Scheduled", game.status
    game.simulate(game.start + 10)
    assert_equal "InProgress", game.status
    game.simulate(game.start + 300)
    assert_equal "Played", game.status

=begin
    events = GameEvent.where(game_id: game.id).order(:time).all
    puts "GAME ======================+"
    events.each do |e|
      puts "#{game.event_minutes e} #{e.kind} InPossession:#{e.side} #{e.ball_pos_x},#{e.ball_pos_y} #{e.message}"
    end
    puts "Final score: #{game.home_goals}:#{game.away_goals}"
=end
  end

  test "simulation_internals" do
    game = games(:seven)
    sim = MatchSimHelper::GameSimulator.new(game)
    amy = players(:amy)
    assert_equal 6, amy.speed
    assert_equal 6 + MatchSimHelper::BASE_SKILL,
                 sim.skill(0, amy, :speed, MatchSimHelper::PitchPos.new(2,4))
    # position bonus
    assert_equal 8 + MatchSimHelper::BASE_SKILL,
                 sim.skill(0, amy, :speed, MatchSimHelper::PitchPos.new(2,5))
    assert_equal 8 + MatchSimHelper::BASE_SKILL,
                 sim.skill(0, amy, :speed, MatchSimHelper::PitchPos.new(2,6))
    # other side of pitch
    assert_equal 6 + MatchSimHelper::BASE_SKILL,
                 sim.skill(1, amy, :speed, MatchSimHelper::PitchPos.new(2,6))
    assert_equal 8 + MatchSimHelper::BASE_SKILL,
                 sim.skill(1, amy, :speed, MatchSimHelper::PitchPos.new(2,0))
  end
end
