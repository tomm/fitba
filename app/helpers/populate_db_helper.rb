require 'digest/md5'
require 'readline'
require "./app/name_gen.rb"

FORMATION_442 = [
    [2, 6], # gk
    [0, 5], [1, 5], [3, 5], [4, 5],
    [0, 3], [1, 3], [3, 3], [4, 3],
    [1, 1], [3, 1]
]

TEAM_NAMES = [
  "Barcelona",
  "Real Madrid",
  "Chelsea",
  "Zenit St Petersburg",
  "AEK Athens",
  "Celtic F.C",
  "Hamburg",
  "S.S. Lazio",
  "Rangers F.C",
  "Paris St-Germain",
  "Red Star Belgrade",
  "Bologna F.C. 1909",

  "Sporting Toulon",
  "St Pauli",
  "U.C. Sampdoria",
  "Partizan",
  "A.S. Livorno Calcio",
  "Besiktas",
  "FC Twente",
  "Athletic Bilbao",
  "Millwall",
  "Portland Timbers",
  "Vag of the South",
  "Cock of the North",
]

module PopulateDbHelper
  class Populate

    def self.go

      puts "Creating leagues..."
      l1 = League.create(rank: 1, name: "First Division", is_finished: false)
      l2 = League.create(rank: 2, name: "Second Division", is_finished: false)

      populate_league(l1)
      populate_league(l2)

      create_user_for_team("tom", Team.find_by(name: "Cock of the North"))
      create_user_for_team("john", Team.find_by(name: "Vag of the South"))
    end

    def self.create_user_for_team(username, team)
      password = Readline.readline("Enter password for user #{username}: ")
      User.create(name: username, team: team, secret: Digest::MD5.hexdigest(password))
    end

    def self.create_fixtures_for_league_season(league_id, season)
      teams = DbHelper::TeamHelper.all_in_league_season(league_id, season)

      now = Time.now
      season_start = Time.new(now.year, now.month, now.day) + 24*3600
      next_start = season_start
      time_slots = [10*3600, 12*3600, 14*3600,
                    16*3600, 18*3600, 20*3600]

      to_play = teams.permutation(2).to_a.shuffle

      # this won't terminate if time_slots.size > teams.size/2
      raise "Too many time slots for number of teams!" unless time_slots.size <= teams.size/2
      # find time_slots.size number of games per 'day', that only include each team once
      days = []
      while to_play.size > 0 do
        day = []
        tid_today = []
        while day.size < time_slots.size and to_play.size > 0 do
          good = to_play.find {|c| (not tid_today.include?(c[0].id)) and (not tid_today.include?(c[1].id))}
          if good == nil then
            puts "Only filled #{day.size}/#{time_slots.size} slots today"
            break
          end
          to_play.delete(good)
          day << good 
          tid_today << good[0].id
          tid_today << good[1].id
        end
        days << day
      end

      days.each do |d|
        d.each_with_index do |match,slot|
          Game.create(league_id: league_id, home_team: match[0], away_team: match[1],
                       status: "Scheduled",
                       start: next_start + time_slots[slot],
                       home_goals: 0, away_goals: 0,
                       season: season)
        end
        next_start += 24*3600
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
        name: NameGen.pick,
        shooting: (0..9).to_a.sample,
        passing: (0..9).to_a.sample,
        tackling: (0..9).to_a.sample,
        handling: (0..9).to_a.sample,
        speed: (0..9).to_a.sample
      )
    end

    def self.make_team

      formation = Formation.create()
      team = Team.create(formation_id: formation.id)
      if nice_name = TEAM_NAMES[team.id-1] then
        team.update(name: nice_name)
      else
        team.update(name: "Team #{team.id}")
      end
      puts "Creating team " + team.name
      (0..16).to_a.map do |i|
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
