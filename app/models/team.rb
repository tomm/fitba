class Team < ActiveRecord::Base
  belongs_to :formation
  has_many :team_leagues

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
      formation: positions.map {|p| [p.position_x, p.position_y]},
      players: squad.map do |p|
        {
          id: p.id,
          name: p.name,
          shooting: p.shooting,
          passing: p.passing,
          tackling: p.tackling,
          handling: p.handling,
          speed: p.speed
        }
      end
    }
  end

  def update_player_positions(positions) # [[playerId, [positionX, positionY]]]
    # positions are in order, ie [0] is goal keeper, [10] is centre forward
    #players = Player.find_by(team_id: self.id)
    positions.each_with_index do |p,i|
      player_id = p[0]
      position_xy = p[1]
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
