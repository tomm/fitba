require 'digest/md5'
require 'readline'
require "./app/name_gen.rb"

SQUAD_SIZE = 22

TRANSFER_LISTING_DURATION = 60*60*24

FORMATION_442 = [
    [2, 6], # gk
    [0, 5], [1, 5], [3, 5], [4, 5],
    [0, 3], [1, 3], [3, 3], [4, 3],
    [1, 1], [3, 1]
]
FORMATION_352 = [
  [2,6],
  [1,5],[2,5],[3,5],
  [2,4],
  [1,3],[3,3],
  [0,2],[4,2],
  [1,1],[3,1]
]
FORMATION_532 = [
  [2,6],
  [1,5],[2,5],[3,5],
  [0,4],[4,4],
  [1,3],[2,3],[3,3],
  [1,1],[3,1]
]
FORMATION_433 = [
  [2,6],
  [0,5],[1,5],[3,5],[4,5],
  [2,3],
  [1,2],[3,2],
  [0,1],[2,1],[4,1]
]
FORMATION_451 = [
  [2,6],
  [0,5],[1,5],[3,5],[4,5],
  [2,4],
  [0,3],[1,3],[3,3],[4,3],
  [2,1]
]
FORMATION_4231 = [
    [2,6],
    [0,5],[1,5],[3,5],[4,5],
    [1,3],[3,3],
    [0,2],[2,2],[4,2],
    [2,1]
]
FORMATION_4231d = [
    [2,6],
    [0,5],[1,5],[3,5],[4,5],
    [1,4],[3,4],
    [0,2],[2,2],[4,2],
    [2,1]
]
FORMATION_4141 = [
  [2,6],
  [0,5],[1,5],[3,5],[4,5],
  [2,3],
  [0,2],[1,2],[3,2],[4,2],
  [2,1]
]
FORMATION_4141d = [
  [2,6],
  [0,5],[1,5],[3,5],[4,5],
  [2,4],
  [0,3],[1,3],[3,3],[4,3],
  [2,1]
]
  
FORMATIONS = [ FORMATION_442, FORMATION_352, FORMATION_433, FORMATION_4231, FORMATION_4231d, FORMATION_4141,
  FORMATION_4141d, FORMATION_451, FORMATION_532 ]

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
      update_transfer_market

      puts "Creating leagues..."
      l1 = League.create(rank: 1, name: "First Division")
      l2 = League.create(rank: 2, name: "Second Division")

      populate_league(l1)
      populate_league(l2)

      create_user_for_team("tom", Team.find_by(name: "Cock of the North"), 10000000)
      create_user_for_team("john", Team.find_by(name: "Vag of the South"), 10000000)
    end

    def self.create_user_for_team(username, team, money)
      password = Readline.readline("Enter password for user #{username}: ")
      User.create(name: username, team: team, money: money, secret: Digest::MD5.hexdigest(password))
      # nuke team formation, so the user has some work to do
      FormationPo.where(formation_id: team.formation_id).delete_all
    end

    def self.team_can_buy(team_id, player)
      # don't let a team buy a player way out of their league
      team = Team.find(team_id)
      # starting 11
      players = team.formation.formation_pos.map {|f| f.player}
      num_players = players.length
      total_skill = players.inject(0){|sum,x|sum + x.skill} # is sum(players.skill)
      avg_skill = total_skill / num_players.to_f
      can_do = player.skill <= avg_skill * 1.25
      puts "Attempt to buy player of skill #{player.skill} by team avg skill #{avg_skill}. Can do? #{can_do}"
      can_do
    end

    def self.repopulate_transfer_market()
      player_skill = [ "0+1d9", "0+1d8", "0+1d7", "0+1d6", "0+1d5", "0+1d4" ]

      num_players = TransferListing.where("deadline > ?", Time.now).count

      while num_players < 20 do
        player = make_player(nil, player_skill.sample)
        price_jiggle = 1.0 + (rand * 0.1)
        TransferListing.create(team_id: player.team_id, status: 'Active', player: player, min_price: player.skill * 200000 * price_jiggle, deadline: Time.now + TRANSFER_LISTING_DURATION)
        num_players += 1
      end
    end

    def self.decide_transfer_market_bids()

      # resolve expired transfer listings
      expired = TransferListing.where("deadline < ?", Time.now).where(status: 'Active').all
      expired.each do |t|
        player = Player.find(t.player_id)
        bids = TransferBid.where(transfer_listing_id: t.id).order(:amount).reverse_order.all.to_a
        seller_user = User.find_by(team_id: player.team_id)
        sold = false

        while bids.length > 0 and sold == false do
          bid = bids.shift
          buyer_user = User.find_by(team_id: bid.team_id)
          
          if buyer_user != nil then
            if buyer_user.money >= bid.amount and team_can_buy(buyer_user.team_id, player) then
              puts "User #{buyer_user} bought #{player} from #{seller_user} #{t}: #{bid}"
              # won bidding
              buyer_user.update(money: buyer_user.money - bid.amount)
              if seller_user then
                seller_user.update(money: seller_user.money + bid.amount)
              end
              player.update(team_id: buyer_user.team_id)
              FormationPo.where(player_id: player.id).delete_all
              # update listing, marking sold
              t.update(winning_bid_id: bid.id, status: 'Sold')
              sold = true
            end
          end
        end

        if sold == false then
          # don't keep expired transfer listings that nobody won
          puts "Transfer listing expired with no winning bids: #{t}"
          # belongs to a player, so maybe sell anyway
          if seller_user != nil then
            seller_user.update(money: seller_user.money + t.min_price)
            FormationPo.where(player_id: player.id).delete_all
            player.update(team_id: nil)
            t.update(status: 'Sold')
          else
            t.update(status: 'Unsold')
          end
        end
      end

      # nuke ancient transfer listings
      TransferListing.where("deadline < ?", Time.now - 60*60*24).delete_all
    end

    def self.update_transfer_market()
      decide_transfer_market_bids
      repopulate_transfer_market
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
            #puts "Only filled #{day.size}/#{time_slots.size} slots today"
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
      #puts "League fixtues run from #{season_start.to_s} to #{next_start}"
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
      #puts "Creating player using #{m[1]} + #{m[2]}d#{m[3]}"

      player = Player.create(
        team_id: team_id,
        name: NameGen.pick,
        shooting: rand_skill.call(),
        passing: rand_skill.call(),
        tackling: rand_skill.call(),
        handling: rand_skill.call(),
        speed: rand_skill.call(),
      )

      player.update(positions: JSON.generate(player.pick_positions(nil)))
      
      player
    end

    def self.repopulate_team(team)
      # XXX need to retire old players
      players = Player.where(team_id: team.id).all.to_a
      num_players = players.size

      # make sure we have some essential positions
      needed_positions = []
      num_gk = (players.select{|p| p.get_positions.contains? [2,6] }).size
      num_dc = (players.select{|p| p.get_positions.contains? [2,5] }).size
      num_mc = (players.select{|p| p.get_positions.contains? [2,3] }).size
      num_st = (players.select{|p| p.get_positions.contains? [2,1] }).size
      (2-num_gk).times do needed_positions << "G" end
      (2-num_dc).times do needed_positions << "DC" end
      (2-num_mc).times do needed_positions << "MC" end
      (1-num_st).times do needed_positions << "A" end

      player_spawn_skill = TEAM_PREDEF[team.id - 1][:player_spawn_skill]

      (num_players..(SQUAD_SIZE-1)).each do |i|
        player = make_player(team.id, player_spawn_skill)
        needed_pos = needed_positions.pop
        if needed_pos != nil then
          player.update(positions: JSON.generate(player.pick_positions(needed_pos)))
        end
      end

      pick_team_formation(team)
    end

    def self.pick_team_formation(team)
      has_user = User.where(team_id: team.id).count > 0
      if has_user then
        # don't help human players ;)
        return
      end

      _players = Player.where(team_id: team.id).all.to_a

      # sort players by skill
      _players.sort! {|a,b| a.skill > b.skill ? -1 : (a.skill < b.skill ? 1 : 0)}

      formation_viability = (FORMATIONS.map do |formation|
        players = _players.dup
        badness = 0

        positions = []
        formation.each do |f|
          can_play_there = players.select {|p| p.get_positions.include? f}
          if can_play_there.size == 0 then
            # FUCK. nobody can play there. try someone who can play near
            can_play_almost_there = players.select {|p|
              poss = p.get_positions
              poss.include? [f[0]-1,f[1]-1] or
              poss.include? [f[0]-1,f[1]] or
              poss.include? [f[0]-1,f[1]+1] or
              poss.include? [f[0],f[1]-1] or
              poss.include? [f[0],f[1]+1] or
              poss.include? [f[0]+1,f[1]-1] or
              poss.include? [f[0]+1,f[1]-0] or
              poss.include? [f[0]+1,f[1]+1]
            }
            if can_play_almost_there.size == 0 then
              # FUCK. there's really nobody. pick at random
              picked = players.sample
              badness += 2
            else
              # take a random bad match ;)
              picked = can_play_almost_there.sample
              badness += 1
            end
          else
            # take best player
            picked = can_play_there[0]
          end
          players.delete(picked)
          positions << [picked.id, f]
        end
        { positions: positions, badness: badness }
      end)

      formation_viability.sort! {|a,b| a[:badness] > b[:badness] ? 1 : (a[:badness] < b[:badness] ? -1 : 0)}

      # pick least worst formation choice
      team.update_player_positions formation_viability[0][:positions]
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
