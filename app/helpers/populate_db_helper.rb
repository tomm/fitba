require 'digest/md5'
require 'readline'
require "./app/name_gen.rb"

FORMATION_442 = [
    [2, 6], # gk
    [0, 5], [1, 5], [3, 5], [4, 5],
    [0, 3], [1, 3], [3, 3], [4, 3],
    [1, 1], [3, 1]
]

TEAMS_PER_LEAGUE = 12

TEAM_PREDEF = [
  {name: "Barcelona", player_spawn_skill: "3+1d6"},
  {name: "Real Madrid", player_spawn_skill: "3+1d6"},
  {name: "Chelsea", player_spawn_skill: "3+1d6"},
  {name: "AEK Athens", player_spawn_skill: "2+1d7"},
  {name: "Celtic F.C", player_spawn_skill: "2+1d7"},
  {name: "Hamburg", player_spawn_skill: "2+1d7"},
  {name: "S.S. Lazio", player_spawn_skill: "1+1d8"},
  {name: "Rangers F.C", player_spawn_skill: "1+1d8"},
  {name: "Paris St-Germain", player_spawn_skill: "1+1d8"},
  {name: "Red Star Belgrade", player_spawn_skill: "0+1d9"},
  {name: "Bologna F.C. 1909", player_spawn_skill: "0+1d9"},
  {name: "Athletic Bilbao", player_spawn_skill: "0+1d9"},

  {name: "Sporting Toulon", player_spawn_skill: "0+1d8"},
  {name: "St Pauli", player_spawn_skill: "0+1d8"},
  {name: "U.C. Sampdoria", player_spawn_skill: "0+1d8"},
  {name: "Partizan", player_spawn_skill: "0+1d7"},
  {name: "Livorno Calcio", player_spawn_skill: "0+1d7"},
  {name: "Besiktas", player_spawn_skill: "0+1d7"},
  {name: "FC Twente", player_spawn_skill: "0+1d6"},
  {name: "Luton Town", player_spawn_skill: "0+1d6"},
  {name: "Millwall", player_spawn_skill: "0+1d6"},
  {name: "Portland Timbers", player_spawn_skill: "0+1d5"},
  {name: "Vag of the South", player_spawn_skill: "0+1d5"},
  {name: "Cock of the North", player_spawn_skill: "0+1d5"},
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
      raise "No teams in league!" unless teams.size > 0

      now = Time.now
      # create fixtures starting tomorrow
      season_start = Time.new(now.year, now.month, now.day) + 24*3600
      next_start = season_start
      time_slots = [10*3600, 12*3600, 14*3600,
                    16*3600, 18*3600, 20*3600]

      to_play = teams.permutation(2).to_a.shuffle

      # this won't terminate if time_slots.size > teams.size/2
      #raise "Too many time slots for number of teams!" unless time_slots.size <= teams.size/2
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
      (1..TEAMS_PER_LEAGUE).to_a.map do |i|
        team = make_team()
        TeamLeague.create(team_id: team.id, league_id: league.id, season: 1)
        team
      end

      puts "Populating league fixtures..."
      create_fixtures_for_league_season(league.id, 1)
    end

    def self.make_player(team_id, player_spawn_skill)
      # player skill as '4+2d6' kinda thing
      m = player_spawn_skill.match(/(\d+)\+(\d+)d(\d+)/)
      dice = lambda {|n,s|
        x=0
        (1..n).each do |_|
          x += 1 + (rand*s).to_i; 
        end
        x
      }
      rand_skill = lambda {
        skill = m[1].to_i + dice.call(m[2].to_i, m[3].to_i)
        skill >= 1 ? (skill <= 9 ? skill : 9) : 1
      }
      puts "Creating player using #{m[1]} + #{m[2]}d#{m[3]}"

      player = Player.create(
        team_id: team_id,
        name: NameGen.pick,
        shooting: rand_skill.call(),
        passing: rand_skill.call(),
        tackling: rand_skill.call(),
        handling: rand_skill.call(),
        speed: rand_skill.call(),
      )

      player.update(name: player.pick_position + " " + player.name)
    end

    def self.repopulate_team(team)
      # XXX need to retire old players
      num_players = Player.where(team_id: team.id).count

      player_spawn_skill = TEAM_PREDEF[team.id - 1][:player_spawn_skill]

      (num_players..18).each do |i|
        make_player(team.id, player_spawn_skill)
      end

      pick_team_formation(team)
    end

    def self.pick_team_formation(team)
      playerIds = Player.where(team_id: team.id).pluck(:id)
      positions = playerIds.each_with_index.map do |playerId,idx|
        [playerId, [idx<11 ? FORMATION_442[idx][0] : 0,
                     idx<11 ? FORMATION_442[idx][1] : 0]]
      end
      team.update_player_positions positions
    end

    def self.make_team
      formation = Formation.create()
      team = Team.create(formation_id: formation.id)
      team_predef = TEAM_PREDEF[team.id-1]
      team.update(name: team_predef[:name])
      puts "Creating team " + team.name
      repopulate_team(team)

      team
    end
  end
end
