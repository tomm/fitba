# Try running with:
# $ RAILS_ENV=development ruby test_server.rb
require "./config/environment"

puts "Fitba server up!"
while sleep 1 do
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
