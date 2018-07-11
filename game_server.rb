# Try running with:
# $ RAILS_ENV=development ruby test_server.rb
require 'date'
require "./config/environment"
require "./app/end_of_season"
require "./app/helpers/populate_db_helper.rb"

daily_tasks_last = nil
DAYS_REST_BETWEEN_SEASONS = 2

puts "Fitba server up!"
while sleep 1 do
  today = Date.today
  if daily_tasks_last != today then
    puts "Executing daily tasks..."
    if EndOfSeason.is_end_of_season? then
      if Date.today - EndOfSeason.last_game_date >= DAYS_REST_BETWEEN_SEASONS then
        EndOfSeason.create_new_season
      end
    end

    puts "Updating transfer market"
    PopulateDbHelper::Populate.update_transfer_market

    daily_tasks_last = today
  end

  now = Time.now
  games = Game.where.not(status: 'Played').where('start < ?', now).all

  if games.size > 0
    puts "#{games.size} games to simulate."
  end

  games.each do |game|
    game.simulate(now)
    puts "Game between #{game.home_team.name} and #{game.away_team.name}: #{game.status}"
  end
end
