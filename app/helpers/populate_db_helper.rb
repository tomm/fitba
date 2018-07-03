require 'digest/md5'

FORMATION_442 = [
    [2, 6], # gk
    [0, 5], [1, 5], [3, 5], [4, 5],
    [0, 3], [1, 3], [3, 3], [4, 3],
    [1, 1], [3, 1]
]

module PopulateDbHelper
  class Populate
    def self.go

      puts "Creating leagues..."
      l1 = League.create(rank: 1, name: "First Division", is_finished: false)
      l2 = League.create(rank: 2, name: "Second Division", is_finished: false)

      populate_league(l1)
      populate_league(l2)

      User.create(name: "tom", team: Team.first, secret: Digest::MD5.hexdigest("password"))
    end

    def self.create_fixtures_for_league_season(league_id, season)
      teams = DbHelper::TeamHelper.all_in_league_season(league_id, season)

      combinations = []
      teams.each do |t1|
        teams.each do |t2|
          if t1 != t2
            combinations << [t1,t2]
            combinations << [t2,t1]
          end
        end
      end

      now = Time.now
      season_start = Time.new(now.year, now.month, now.day) + 24*3600
      next_start = season_start
      time_slots = [12*3600, 13*2600, 14*3600, 15*3600, 16*3600,
                    17*3600, 18*3600, 19*3600, 20*3600, 21*3600]
      slot = 0

      # XXX TODO randomize!!
      combinations.each do |c|
        Game.create(league_id: league_id, home_team: c[0], away_team: c[1],
                     status: "Scheduled",
                     start: next_start + time_slots[slot],
                     home_goals: 0, away_goals: 0,
                     season: season)
        slot += 1
        if slot >= time_slots.size
          next_start += 24*3600
          slot = 0
        end
      end
      puts "League fixtues run from #{season_start.to_s} to #{next_start}"
    end

    def self.populate_league(league)
      puts "Populating league: " + league.name
      (1..12).to_a.map do |i|
        team = make_team()
        TeamLeague.create(team_id: team.id, league_id: league.id, season: 1)
        team
      end

      puts "Populating league fixtures..."
      create_fixtures_for_league_season(league.id, 1)
    end

    def self.make_player(team_id)
      Player.create(
        team_id: team_id,
        name: "Player " + (0..99).to_a.sample.to_s,
        shooting: (0..9).to_a.sample,
        passing: (0..9).to_a.sample,
        tackling: (0..9).to_a.sample,
        handling: (0..9).to_a.sample,
        speed: (0..9).to_a.sample
      )
    end

    def self.make_team

      formation = Formation.create()
      team = Team.create(name: "Team " + rand().to_s, formation_id: formation.id)
      puts "Creating team " + team.name
      (0..21).to_a.map do |i|
        player = make_player(team.id)
        FormationPo.create(formation_id: formation.id, player_id: player.id,
                           position_num: i,
                           position_x: i<11 ? FORMATION_442[i][0] : 0,
                           position_y: i<11 ? FORMATION_442[i][1] : 0)
      end
      team
    end
  end
end
