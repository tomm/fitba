# Try running with:
# $ RAILS_ENV=development ruby test_server.rb
require 'date'
require "./config/environment"
require "./app/helpers/populate_db_helper.rb"

daily_tasks_last = nil
DAYS_REST_BETWEEN_SEASONS = 2

five_minutely_tasks_last = nil

puts "Fitba server up!"
while sleep 1 do
  now = Time.now
  today = Date.today

  if daily_tasks_last != today then
    puts "Executing daily tasks..."
    if SeasonHelper.is_end_of_season? then
      if Date.today - SeasonHelper.last_game_date >= DAYS_REST_BETWEEN_SEASONS then
        SeasonHelper.handle_end_of_season
      end
    end

    # update team formations
    Team.all.each do |t|
      puts "Updating formation of #{t.name}"
      AiManagerHelper.pick_team_formation(t)
    end

    daily_tasks_last = today
  end

  if five_minutely_tasks_last == nil or now - five_minutely_tasks_last > 5*60 then
    puts "Executing five-minutely tasks..."
    TransferMarketHelper.update_transfer_market

    five_minutely_tasks_last = now
  end
  
  games = Game.where.not(status: 'Played').where('start < ?', now).all

  if games.size > 0
    puts "#{games.size} games to simulate."
  end

  games.each do |game|
    game.simulate(now)
    puts "Game between #{game.home_team.name} and #{game.away_team.name}: #{game.status} (#{game.home_goals}:#{game.away_goals})"
  end
end
