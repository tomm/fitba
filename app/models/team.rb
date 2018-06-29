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
      players: squad
    }
  end
end
