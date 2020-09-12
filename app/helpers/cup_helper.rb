# typed: true
module CupHelper
  def self.update_cup(cup, season)
    if not is_end_of_round(cup, season) then
      puts "nothing to do in update_cup..."
      return
    end

    team_ids = team_ids_still_in_cup(cup, season)

    if team_ids.size <= 1 then
      # cup has ended for this season. do nothing
    else
      generate_games(cup, season, team_ids)
    end
  end

  def self.generate_games(cup, season, team_ids)
    num_teams = team_ids.size
    stage_size = self.next_power_of_two(num_teams)
    num_empty = stage_size - num_teams

    # when did the last cup match happen?
    r = Game.where(league_id: cup.id, season: season).select("MAX(start) as t").to_a[0]
    if r.nil? || r['t'].nil? then
      last_start = Time.now
    else
      last_start = r['t']
    end
    next_start = Time.new(last_start.year, last_start.month, last_start.day) + 24*3600 + 22*3600

    # if number of teams is non-power-of-two then some teams don't play this round. skip them
    team_ids.shift(num_empty)
    team_ids.shuffle!

    # make games
    raise "Error in CupHelper.generate_games. odd number of teams..." unless team_ids.size % 2 == 0
    while team_ids.size > 0 do
      team1 = team_ids.shift
      team2 = team_ids.shift
      puts "Cup game: #{team1} vs #{team2} on #{next_start}"
      Game.create(league_id: cup.id, home_team_id: team1, away_team_id: team2,
                   status: "Scheduled",
                   start: next_start,
                   stage: stage_size / 2,
                   home_goals: 0, away_goals: 0,
                   season: season)
      next_start += 24*3600
    end
  end

  def self.is_end_of_round(cup, season)
    Game.where(league_id: cup.id, season: season).where.not(status: "Played").count == 0
  end

  def self.team_ids_still_in_cup(cup, season)
    # all teams take part in cup
    # XXX note we have low id teams first. this means they are skipped from
    # preliminary cup rounds if num teams is non-power-of-two (see generate_games)
    # Would be better to do this by previous season's standing
    teams_in_cup = Team.order(:id).pluck(:id)
    games = Game.where(league_id: cup.id, season: season, status: "Played").all

    # remove eliminated teams
    games.each {|g|
      winner, loser = g.winner_loser
      teams_in_cup.delete(loser.id)
    }
    
    teams_in_cup
  end

  # 31 -> 32, 32 -> 32, 33 -> 64
  def self.next_power_of_two(n)
    n -= 1
    n |= n >> 1
    n |= n >> 2
    n |= n >> 4
    n |= n >> 8
    n |= n >> 16
    n + 1
  end
end
