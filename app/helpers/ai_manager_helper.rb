module AiManagerHelper
  SQUAD_MIN_SIZE = 20
  SQUAD_MAX_SIZE = 30

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

  def self.daily_task(team)
    if team.has_user? then
      return
    end

    if RngHelper.dice(1,10) == 1 then
      maybe_acquire_player(team)
    end
    if RngHelper.dice(1,10) == 1 then
      maybe_sell_player(team)
    end
    
    AiManagerHelper.pick_team_formation(team)
  end

  def self.maybe_acquire_player(team)
    if team.has_user? || team.players.count >= SQUAD_MAX_SIZE then
      return
    end

    p = Player.random(team.player_spawn_quality)
    p.team_id = team.id
    p.save
    pick_team_formation(team)
    puts "Team #{team.name} signed new player #{p.name}"
  end

  def self.maybe_sell_player(team)
    if team.has_user? then
      return
    end

    players = team.players.to_a

    # team too small
    if players.size <= SQUAD_MIN_SIZE then
      return
    end

    pos_freq = _player_position_frequency(team).to_a.sort_by { |a| -a[1] }
    commonest_pos = pos_freq
      .take_while { |v| v[1] == pos_freq.first[1] }
      .map { |v| v[0] }

    _sell_player_in_position(team, commonest_pos.sample)
  end

  private_class_method
  def self._sell_player_in_position(team, pos)
    matching = team.players.select {|p| p.get_positions.include? pos}
    to_sell = matching.sort_by!(&:skill).first
    puts "Team #{team.name} has listed #{to_sell.name} on the transfer market."
    TransferMarketHelper.list_player(to_sell)
  end

  private_class_method
  def self._player_position_frequency(team)
    freqs = {}
    team.players.each do |p|
      p.get_positions.each do |pos|
        freqs[pos] ||= 0
        freqs[pos] += 1
      end
    end
    freqs
  end

  def self.pick_team_formation(team)
    if team.has_user? then
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

        if picked != nil then
          players.delete(picked)
          positions << [picked.id, f]
        end
      end
      { positions: positions, badness: badness }
    end)

    formation_viability.sort! {|a,b| a[:badness] > b[:badness] ? 1 : (a[:badness] < b[:badness] ? -1 : 0)}

    # pick least worst formation choice
    team.update_player_positions formation_viability[0][:positions]
  end
end