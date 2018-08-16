require 'digest/md5'
require 'readline'
require "./app/name_gen.rb"

SQUAD_SIZE = 22

TEAMS_PER_LEAGUE = 12

TEAM_PREDEF = [
  {name: "Barcelona", player_spawn_quality: 9},
  {name: "Real Madrid", player_spawn_quality: 9},
  {name: "Chelsea", player_spawn_quality: 8},
  {name: "AEK Athens", player_spawn_quality: 8},
  {name: "Celtic F.C", player_spawn_quality: 7},
  {name: "Hamburg", player_spawn_quality: 7},
  {name: "S.S. Lazio", player_spawn_quality: 6},
  {name: "Rangers F.C", player_spawn_quality: 6},
  {name: "Paris St-Germain", player_spawn_quality: 6},
  {name: "Red Star Belgrade", player_spawn_quality: 5},
  {name: "Bologna F.C. 1909", player_spawn_quality: 5},
  {name: "Athletic Bilbao", player_spawn_quality: 5},

  {name: "Sporting Toulon", player_spawn_quality: 4},
  {name: "St Pauli", player_spawn_quality: 4},
  {name: "U.C. Sampdoria", player_spawn_quality: 4},
  {name: "Partizan", player_spawn_quality: 3},
  {name: "Livorno Calcio", player_spawn_quality: 3},
  {name: "Besiktas", player_spawn_quality: 3},
  {name: "FC Twente", player_spawn_quality: 2},
  {name: "Luton Town", player_spawn_quality: 2},
  {name: "Ozan Utd", player_spawn_quality: 2},
  {name: "FC Krøne", player_spawn_quality: 1},
  {name: "Vag of the South", player_spawn_quality: 1},
  {name: "Cock of the North", player_spawn_quality: 1},
]

module PopulateDbHelper
  @@next_team_idx = 0

  def self.go
    TransferMarketHelper.update_transfer_market

    Rails.logger.info "Creating leagues..."
    l1 = League.create(rank: 1, name: "First Division")
    l2 = League.create(rank: 2, name: "Second Division")

    populate_league(l1)
    populate_league(l2)

    create_user_for_team("tom", Team.find_by(name: "Cock of the North"), 10000000)
    create_user_for_team("john", Team.find_by(name: "Vag of the South"), 10000000)
    create_user_for_team("pete", Team.find_by(name: "FC Krøne"), 10000000)
    create_user_for_team("ozan", Team.find_by(name: "Ozan Utd"), 10000000)
  end

  def self.create_user_for_team(username, team, money)
    password = Readline.readline("Enter password for user #{username}: ")
    team.update(money: money)
    User.create(name: username, team: team, secret: Digest::MD5.hexdigest(password))
    # nuke team formation, so the user has some work to do
    FormationPo.where(formation_id: team.formation_id).delete_all
    # then just assign a crap 442
    fm442 = [
        [2, 6], # gk
        [0, 5], [1, 5], [3, 5], [4, 5],
        [0, 3], [1, 3], [3, 3], [4, 3],
        [1, 1], [3, 1]
    ]
    playerIds = Player.where(team_id: team.id).pluck(:id)
    positions = playerIds.each_with_index.map do |playerId,idx|
      [playerId, [idx<11 ? fm442[idx][0] : 0,
                   idx<11 ? fm442[idx][1] : 0]]
    end
    team.update_player_positions positions
  end

  def self.populate_league(league)
    Rails.logger.info "Populating league: " + league.name
    (0...TEAMS_PER_LEAGUE).to_a.map do |i|
      team = make_team(TEAM_PREDEF[@@next_team_idx])
      @@next_team_idx += 1
      TeamLeague.create(team_id: team.id, league_id: league.id, season: 1)
      team
    end

    Rails.logger.info "Populating league fixtures..."
    SeasonHelper.create_fixtures_for_league_season(league.id, 1)
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

    (num_players..(SQUAD_SIZE-1)).each do |i|
      player = Player.random(team.player_spawn_quality)
      player.team_id = team.id
      player.save
      needed_pos = needed_positions.pop
      if needed_pos != nil then
        player.update(positions: JSON.generate(player.pick_positions(needed_pos)))
      end
    end

    AiManagerHelper.pick_team_formation(team)
  end

  def self.make_team(name: nil, player_spawn_quality: 5)
    formation = Formation.create()
    Rails.logger.info "Creating team " + name
    team = Team.create(name: name,
                       player_spawn_quality: player_spawn_quality,
                       formation_id: formation.id)
    repopulate_team(team)

    team
  end
end
