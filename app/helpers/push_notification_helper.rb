# typed: true
require 'fcm'

module PushNotificationHelper
  def self.test_config
    raise 'Missing FIREBASE_SERVER_KEY variable' unless ENV['FIREBASE_SERVER_KEY'] || ENV['RAILS_ENV'] == 'development'
  end

  def self.get_firebase
    server_key = ENV['FIREBASE_SERVER_KEY']
    if server_key != nil
      FCM.new(server_key)
    else
      puts 'WARNING: Missing FIREBASE_SERVER_KEY variable. No push notifications'
      nil
    end
  end

  def self.send_to_manager_of_team_id(team_id, title, body, click_url)
    team = Team.find(team_id)
    return unless team.is_actively_managed_by_human?

    token = UserFcmToken.for_team_id(team_id).pluck(:token)
    return unless token.present?

    options = {
      notification: {
        title: title,
        body: body,
        click_action: click_url
      }
    }

    get_firebase&.send(token, options)
  end

  def self.send_result_notifications(game)
    pens = if game.home_penalties == 0 && game.away_penalties == 0 then
             ''
           else
             " (#{game.home_penalties}:#{game.away_penalties} P)"
           end
    title = "Final score: #{game.home_team.name} #{game.home_goals}:#{game.away_goals}#{pens} #{game.away_team.name}"
    body = GameEvent.where(game_id: game.id, kind: 'Goal').map {|e|
      player_name = Player.find(e.player_id).name
      mins = game.time_to_match_minutes(e.time)
      if e.side == 0
        "#{mins} #{player_name} (#{game.home_team.name})"
      else
        "#{mins} #{player_name} (#{game.away_team.name})"
      end
    }.join("\n")
    send_to_manager_of_team_id(
      game.home_team_id, title, body, 'https://myfitba.club/'
    )
  end
end
