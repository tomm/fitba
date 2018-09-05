#!/usr/bin/env ruby
# Try running with:
# $ RAILS_ENV=development ruby test_server.rb
require 'date'
require "./config/environment"
require "./app/helpers/populate_db_helper.rb"

daily_tasks_last = Date.today
DAYS_REST_BETWEEN_SEASONS = 1

five_minutely_tasks_last = nil

def daily_task
  Rails.logger.info "executing daily tasks..."
  if SeasonHelper.is_end_of_season? then
    if Date.today - SeasonHelper.last_game_date >= DAYS_REST_BETWEEN_SEASONS then
      SeasonHelper.handle_end_of_season
    end
  end

  League.is_cup.each{|cup|
    CupHelper.update_cup(cup, SeasonHelper.current_season)
  }
  PlayerHelper.daily_develop_youth_players
  PlayerHelper.daily_cure_injury
  PlayerHelper.daily_maybe_change_player_form

  # AI update
  Team.all.each do |t|
    AiManagerHelper.daily_task(t)
  end
end

def five_minutely_task
  Rails.logger.info "executing five-minutely tasks..."
  TransferMarketHelper.update_transfer_market
  PlayerHelper.spawn_injuries
end

def per_second_task(now)
  games = Game.where.not(status: 'Played').where('start < ?', now).all

  if games.size > 0
    Rails.logger.info "#{games.size} games to simulate."
  end

  games.each do |game|
    game.simulate(now)
    pens = if game.home_penalties > 0 or game.away_penalties > 0 then " Penalties: #{game.home_penalties}:#{game.away_penalties}" else "" end
    Rails.logger.info "#{game.league.kind} game between #{game.home_team.name} and #{game.away_team.name}: #{game.status} (#{game.home_goals}:#{game.away_goals}) #{pens}"
  end
end

if __FILE__ == $0 then
  Rails.logger.info "Fitba server up!"

  if ARGV[0] == "season" then
    puts "Simulating whole season........................"
    daily_task
    per_second_task(Time.now + 40*24*3600)
  end

  while sleep 1 do
    now = Time.now
    today = Date.today

    if daily_tasks_last != today then
      daily_task()
      daily_tasks_last = today
    end

    if five_minutely_tasks_last == nil or now - five_minutely_tasks_last > 5*60 then
      five_minutely_task()
      five_minutely_tasks_last = now
    end
    
    per_second_task(Time.now)
  end
end
