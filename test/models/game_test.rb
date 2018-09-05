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
    game.simulate(game.start + 500)
    assert_equal "Played", game.status

#=begin
    events = GameEvent.where(game_id: game.id).order(:time).all
    puts "GAME ======================+"
    events.each do |e|
      puts "#{game.event_minutes e} #{e.time} #{e.kind} InPossession:#{e.side} #{e.ball_pos_x},#{e.ball_pos_y} #{e.message}"
    end
    puts "Final score: #{game.home_goals}:#{game.away_goals}."
    puts "Shootout result (if it happened...): #{game.home_penalties}:#{game.away_penalties}."
    home_shots_missed = GameEvent.where(game: game, side: 0, kind: "ShotMiss").count
    away_shots_missed = GameEvent.where(game: game, side: 1, kind: "ShotMiss").count
    home_shots_total = GameEvent.where(game: game, side: 0, kind: "ShotTry").count
    away_shots_total = GameEvent.where(game: game, side: 1, kind: "ShotTry").count
    puts "Shots total: #{home_shots_total}:#{away_shots_total}"
    puts "Missed: #{home_shots_missed}:#{away_shots_missed}"
    puts "On target: #{home_shots_total - home_shots_missed}:#{away_shots_total - away_shots_missed}"
#=end
  end

  test "simulation_internals" do
    game = games(:seven)
    sim = MatchSimHelper::GameSimulator.new(game)
    amy = players(:amy)
    assert_equal 6, amy.speed
    assert_equal 6 + MatchSimHelper::BASE_SKILL,
                 sim.skill(0, amy, :speed, MatchSimHelper::PitchPos.new(2,4))
    # position bonus
    assert_equal 6 + MatchSimHelper::BASE_SKILL,
                 sim.skill(0, amy, :speed, MatchSimHelper::PitchPos.new(2,5))
    assert_equal 8 + MatchSimHelper::BASE_SKILL,
                 sim.skill(0, amy, :speed, MatchSimHelper::PitchPos.new(2,6))
    # other side of pitch
    assert_equal 6 + MatchSimHelper::BASE_SKILL,
                 sim.skill(1, amy, :speed, MatchSimHelper::PitchPos.new(2,6))
    assert_equal 8 + MatchSimHelper::BASE_SKILL,
                 sim.skill(1, amy, :speed, MatchSimHelper::PitchPos.new(2,0))
  end

  test "media_response" do
    game = games(:seven)
    game.home_goals = 7
    game.away_goals = 1
    game.status = 'Played'
    num_news = NewsArticle.count
    sim = MatchSimHelper::GameSimulator.new(game)
    10.times do
      sim.media_response
    end
    assert_equal num_news+10, NewsArticle.count
  end
end
