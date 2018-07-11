# Try running with:
# $ RAILS_ENV=development ruby test_server.rb
require 'date'
require "./config/environment"
require "./app/end_of_season"
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
    if EndOfSeason.is_end_of_season? then
      if Date.today - EndOfSeason.last_game_date >= DAYS_REST_BETWEEN_SEASONS then
        EndOfSeason.create_new_season
      end
    end

    daily_tasks_last = today
  end

  if five_minutely_tasks_last == nil or now - five_minutely_tasks_last > 5*60 then
    puts "Executing five-minutely tasks..."
    PopulateDbHelper::Populate.update_transfer_market

    five_minutely_tasks_last = now
  end
  
  games = Game.where.not(status: 'Played').where('start < ?', now).all

  if games.size > 0
    puts "#{games.size} games to simulate."
  end

  games.each do |game|
    game.simulate(now)
    puts "Game between #{game.home_team.name} and #{game.away_team.name}: #{game.status}"
  end
end
