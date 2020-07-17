#!/usr/bin/env ruby
# Try running with:
# $ RAILS_ENV=development ruby game_server.rb
require 'date'
require "./config/environment"
require "./app/helpers/populate_db_helper"
require "./app/helpers/spring_clean_db_helper"
require "./app/helpers/push_notification_helper"

daily_tasks_last = Date.today
DAYS_REST_BETWEEN_SEASONS = 1

five_minutely_tasks_last = nil

PushNotificationHelper.test_config()

def daily_task
  Rails.logger.info "executing daily tasks..."
  if SeasonHelper.is_end_of_season? then
    if Date.today - SeasonHelper.last_game_date >= DAYS_REST_BETWEEN_SEASONS then
      SeasonHelper.handle_end_of_season
      SpringCleanDbHelper.go
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
  
  # AI update
  Team.all.each do |t|
    AiManagerHelper.five_minutely_task(t)
  end
end

def notify_game_starting(team_id, is_home, opponent_name)
  puts "Fcm notification to manager of team id #{team_id}"
  PushNotificationHelper.send_to_manager_of_team_id(
    team_id,
    "Your #{is_home ? 'home' : 'away'} game against #{opponent_name} starts in 5 minutes!",
    '',
    'https://myfitba.club/'
  )
end

def notify_games_starting(now)
  Game.where.not(status: 'Played')
      .where.not(notified: true)
      .where('start < ?', now + (60 * 5))
      .each do |g|

    notify_game_starting(g.home_team_id, true, g.away_team.name)
    notify_game_starting(g.away_team_id, false, g.home_team.name)
    g.update(notified: true)
  end
end

def per_second_task(now)
  notify_games_starting(now)

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
