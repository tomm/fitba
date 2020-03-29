require_relative './season_helper'

module SpringCleanDbHelper
  def self.go
    season = SeasonHelper.current_season

    total = GameEvent.count
    # the inconsistency in relation naming in ActiveRecord really sucks
    to_nuke = GameEvent.joins(:game).where.not(kind: ['Goal', 'Injury']).where.not(games: { season: season })
    puts "SpringCleanDbHelper: Total game events: #{total}. to nuke (from past seasons): #{to_nuke.count}"
    to_nuke.delete_all

    puts "SpringCleanDbHelper: Deleting players who were never linked to clubs..."
    ActiveRecord::Base.connection.execute("
      delete from players
      where team_id is null
        and not exists (
          select * from formation_pos where player_id=players.id
        )
        and not exists (
          select * from game_events where player_id=players.id
        )
        and not exists (
          select * from transfer_listings where player_id=players.id
        )
        and created_at < now() - interval '1 month'
    ")

    puts "SpringCleanDbHelper: Full vacuum on whole DB"
    ActiveRecord::Base.connection.execute('VACUUM FULL')
    nil
  end
end
