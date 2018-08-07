module AiManagerHelper
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
end
