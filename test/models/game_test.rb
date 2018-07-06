require 'test_helper'

class GameTest < ActiveSupport::TestCase
  test "simulate" do
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
      puts "#{game.event_minutes e} #{e.kind} Home?#{e.side} #{e.ball_pos_x},#{e.ball_pos_y} #{e.message}"
    end
    puts "Final score: #{game.home_goals}:#{game.away_goals}"
=end
  end
end
