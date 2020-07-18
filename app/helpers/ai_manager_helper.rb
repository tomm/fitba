module AiManagerHelper
  SQUAD_MIN_SIZE = 20
  SQUAD_MAX_SIZE = 30

  FORMATION_442 = [
      [2, 6], # gk
      [0, 5], [1, 5], [3, 5], [4, 5],
      [0, 3], [1, 3], [3, 3], [4, 3],
      [1, 1], [3, 1]
  ]
  FORMATION_4411 = [
      [2, 6],
      [0, 5], [1, 5], [3, 5], [4, 5],
      [0, 3], [1, 3], [3, 3], [4, 3],
      [2, 2], [2, 1]
  ]
  FORMATION_4411a = [
      [2, 6],
      [0, 4], [1, 5], [3, 5], [4, 4],
      [0, 2], [1, 3], [3, 3], [4, 2],
      [2, 2], [2, 1]
  ]
  FORMATION_VAG = [
      [2,6], # gk
      [0,4], [1,5], [3,5], [4,4],
      [2,3],
      [0,2],[2,2],[4,2],
      [1,1],[3,1]
  ]
  FORMATION_442_wingback_diamond = [
      [2, 6], # gk
      [0, 4], [1, 5], [3, 5], [4, 4],
      [2, 4], [1, 3], [3, 3], [2, 2],
      [1, 1], [3, 1]
  ]
  FORMATION_442_diamond = [
      [2, 6], # gk
      [0, 5], [1, 5], [3, 5], [4, 5],
      [2, 4], [1, 3], [3, 3], [2, 2],
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
  FORMATION_433a = [
    [2,6],
    [0,5],[1,5],[3,5],[4,5],
    [1,3],[2,3],[3,3],
    [0,1],[2,1],[4,1]
  ]
  FORMATION_433 = [
    [2,6],
    [0,5],[1,5],[3,5],[4,5],
    [1,3],[2,3],[3,3],
    [0,2],[2,1],[4,2]
  ]
  FORMATION_433d = [
    [2,6],
    [0,5],[1,5],[3,5],[4,5],
    [1,3],[2,4],[3,3],
    [0,2],[2,1],[4,2]
  ]
  FORMATION_451m = [
    [2,6],
    [0,5],[1,5],[3,5],[4,5],
    [0,3],[1,3],[2,3],[3,3],[4,3],
    [2,1]
  ]
  FORMATION_451d = [
    [2,6],
    [0,5],[1,5],[3,5],[4,5],
    [2,4],
    [0,3],[1,3],[3,3],[4,3],
    [2,1]
  ]
  FORMATION_451a = [
    [2,6],
    [0,5],[1,5],[3,5],[4,5],
    [0,2],[1,3],[2,3],[3,3],[4,2],
    [2,1]
  ]
  FORMATION_4231a = [
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
  FORMATION_4231 = [
      [2,6],
      [0,5],[1,5],[3,5],[4,5],
      [1,4],[3,4],
      [0,2],[2,3],[4,2],
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
  FORMATIONS = [ FORMATION_442, FORMATION_352, FORMATION_433, FORMATION_433a,
                 FORMATION_433d, FORMATION_4231,
                 FORMATION_4231a, FORMATION_4231d, FORMATION_4141, FORMATION_4141d,
                 FORMATION_451m, FORMATION_451d, FORMATION_451a, FORMATION_532,
                 FORMATION_442_diamond, FORMATION_442_wingback_diamond,
                 FORMATION_VAG, FORMATION_4411, FORMATION_4411a ]

  def self.five_minutely_task(team)
    if team.is_actively_managed_by_human? then
      return
    end

    # roughly once every 2 days
    runs_per_day = 60*24/5
    chance_of_transfer = runs_per_day*2

    if RngHelper.dice(1,chance_of_transfer) == 1 then
      maybe_acquire_player(team)
    end
    if RngHelper.dice(1,chance_of_transfer) == 1 then
      maybe_sell_player(team)
    end
    
  end

  def self.daily_task(team)
    if team.is_actively_managed_by_human? then
      return
    end

    AiManagerHelper.pick_team_formation(team)
  end

  def self.maybe_acquire_player(team)
    if team.is_actively_managed_by_human? then
      return
    end

    if team.players.count >= SQUAD_MAX_SIZE then
      Rails.logger.info "#{team.name} too large to make signings."
      return
    end

    # find transfer listings that are right skill level for this team
    tls = TransferListing.where('team_id != ?', team.id).where(status: 'Active').to_a.select { |l|
      (
        l.player.skill >= (team.player_spawn_quality - 1.5) * 5 &&
        l.player.skill <= (team.player_spawn_quality + 1) * 5 &&
        l.player.age <= 34
      )
    }

    # pick one at random and bid on it...
    tl = tls.sample
    if !tl.nil? then
      bid = TransferBid.create(
        transfer_listing_id: tl.id,
        team_id: team.id,
        amount: tl.min_price + RngHelper.dice(1, tl.min_price),
        status: 'Pending'
      )
      Rails.logger.info "Team #{team.name} have bid #{bid.amount} for listed player #{tl.player.name} (min bid #{tl.min_price})"
    end
  end

  def self.maybe_sell_player(team)
    if team.is_actively_managed_by_human? then
      return
    end

    players = team.players.to_a

    # team too small
    if players.size <= SQUAD_MIN_SIZE then
      return
    end

    pos_freq = _player_position_frequency(team)

    # subtract formation positions, since we are using players in those positions
    team.formation.formation_pos.each do |formation_pos|
      pos = [formation_pos.position_x, formation_pos.position_y]
      pos_freq[pos] ||= 0
      # allowance of 2 players per used formation position, so considers subs ;)
      pos_freq[pos] -= 1.5
    end
    pos_freq = pos_freq.to_a.sort_by! { |a| -a[1] }

    most_surplus_position = pos_freq
      .take_while { |v| v[1] == pos_freq.first[1] }
      .map { |v| v[0] }

    _sell_player_in_position(team, most_surplus_position.sample)
  end

  private_class_method
  def self._sell_player_in_position(team, pos)
    matching = team.players.select {|p| p.get_positions.include? pos}
    to_sell = matching.sort_by!(&:skill).first
    Rails.logger.info "Team #{team.name} has listed #{to_sell.name} on the transfer market."
    TransferMarketHelper.list_player(to_sell)
  end

  private_class_method
  def self._player_position_frequency(team)
    freqs = {}
    team.players.each do |p|
      poss = p.get_positions
      weight = 1.0 / poss.size()
      p.get_positions.each do |pos|
        freqs[pos] ||= 0
        freqs[pos] += weight
      end
    end
    freqs
  end

  # used to estimate how good a formation is
  def self.player_value_at(player, position)
    player.form * 5 + (
      if position[1] == 6 then
        5 * (player.handling + player.speed) / 2
      elsif position[1] == 1 then
        player.shooting * 5
      else
        player.skill
      end
    )
  end

  def self.pick_team_formation(team)
    if team.is_actively_managed_by_human? then
      # don't help human players ;)
      return
    end

    _players = Player.where(team_id: team.id, injury: 0).all.to_a

    formation_viability = (FORMATIONS.map do |formation|
      players = _players.dup
      goodness = 0

      positions = []
      formation.each do |f|
        players.sort_by! {|a| -self.player_value_at(a, f)}
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
            if picked != nil then
              goodness += player_value_at(picked, f) + 5
            end
          else
            # take a random bad match ;)
            picked = can_play_almost_there.sample
            goodness += player_value_at(picked, f)
          end
        else
          # take best player
          picked = can_play_there[0]
          goodness += player_value_at(picked, f) + 10
        end

        if picked != nil then
          players.delete(picked)
          positions << [picked.id, f]
        end
      end

      # finally add the remaining players (not chosen for starting 11)
      # in order of skill
      players.sort_by {|p| -p.skill}.each {|p| positions << [p.id, [0,0]]}

      { positions: positions, goodness: goodness }
    end)

    formation_viability.sort! {|a,b| a[:goodness] > b[:goodness] ? -1 : (a[:goodness] < b[:goodness] ? 1 : 0)}

    # pick best formation
    team.update_player_positions formation_viability[0][:positions]
  end
end
