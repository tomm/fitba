module DbHelper
  class SeasonHelper
    # () -> int
    def self.current
      r = ActiveRecord::Base.connection.execute("select max(season) as max from games")
      raise "No fixtures exist!" unless r.present?
      r[0]["max"]
    end
  end

  class TeamHelper
    def self.all_in_league_season(league_id, season)
      Team.joins(:team_leagues).where({
        team_leagues: {
          league_id: league_id,
          season: season
        }
      }).all
    end
  end

  class LeagueHelper
    def self.league_table(league_id, season)
      teams = TeamHelper.all_in_league_season(league_id, season)
      games = Game.where(league_id: league_id, season: season, status: "Played").all
      record = (teams.map do |t|
        [ t.id,
          { teamId: t.id, name: t.name,
            played: 0, won: 0, drawn: 0, lost: 0, goalsFor: 0, goalsAgainst: 0 }
        ]
      end).to_h

      games.each do |g|
        home = record[g.home_team_id]
        away = record[g.away_team_id]
        home[:played] += 1
        away[:played] += 1
        if g.home_goals > g.away_goals
          home[:won] += 1
          away[:lost] += 1
        elsif g.home_goals < g.away_goals
          home[:lost] += 1
          away[:won] += 1
        else
          home[:drawn] += 1
          away[:drawn] += 1
        end
        home[:goalsFor] += g.home_goals
        home[:goalsAgainst] += g.away_goals
        away[:goalsFor] += g.away_goals
        away[:goalsAgainst] += g.home_goals
      end

      record.values.sort do |a,b|
        a_pts = 3*a[:won] + a[:drawn]
        b_pts = 3*b[:won] + b[:drawn]
        a_gd = a[:goalsFor] - a[:goalsAgainst]
        b_gd = b[:goalsFor] - b[:goalsAgainst]
        if a_pts > b_pts
          -1
        elsif a_pts < b_pts
          1
        elsif a_gd > b_gd
          -1
        elsif a_gd < b_gd
          1
        elsif a[:goalsFor] > b[:goalsFor]
          -1
        elsif a[:goalsFor] < b[:goalsFor]
          1
        else
          # shit. they are equal. what other deciding factor can there be?
          0
        end
      end
    end
  end
end
