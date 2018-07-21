class Team < ActiveRecord::Base
  belongs_to :formation
  has_many :team_leagues
  has_many :players

  def squad
    positions = FormationPo.where(formation_id: self.formation_id).order(:position_num).all
    players = Player.where(team_id: self.id).all
    squad = []

    # add starting players in order
    positions.each do |pos|
      player = players.detect {|p| p.id == pos.player_id}
      squad << player unless player == nil
    end

    # then add non-starters
    squad |= players

    {
      # make sure there are 11 positions!
      formation: positions = ((0..10).map do |i|
        if positions[i] == nil then
          FORMATION_442[i]
        else
          [positions[i].position_x, positions[i].position_y]
        end
      end),
      players: squad.map {|p| p.to_api }
    }
  end

  def update_player_positions(positions) # [[playerId, [positionX, positionY]]]
    # positions are in order, ie [0] is goal keeper, [10] is centre forward
    #players = Player.find_by(team_id: self.id)
    # move existing positions away
    FormationPo.where(formation_id: self.formation_id).update_all(position_num: 12)
    positions.each_with_index do |p,i|
      player_id = p[0]
      position_xy = p[1]
      if position_xy == nil then position_xy = [0,0] end
      # ^^ haskell version handles this differently, saving a combined "Maybe (Int,Int) field to DB
      # first check it's our player
      if Player.exists?(id: player_id, team_id: self.id)
        formation_po = FormationPo.find_by(player_id: player_id, formation_id: self.formation_id)
        if formation_po == nil
          FormationPo.create(formation_id: self.formation_id,
                             player_id: player_id,
                             position_num: i,
                             position_x: position_xy[0], position_y: position_xy[1])
        else
          formation_po.update(position_num: i, position_x: position_xy[0], position_y: position_xy[1])
        end
      else
        # player is not on this team
        logger.warn("Error (silly client): attempted to save player_id #{player_id} to formation on team #{self.id}, but player does not belong to this team.")
      end
    end
  end
end
