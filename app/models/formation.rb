# typed: strict
class Formation < ApplicationRecord
  extend T::Sig

  has_many :formation_pos

  sig {returns(FormationPo::ActiveRecord_Relation)}
  def positions_ordered
    FormationPo.where(formation_id: self.id).order(:position_num)
  end

  sig {returns(String)}
  def to_s
    "Formation " + positions_ordered.map{|p| "#{p.player.name}:#{p.position_x},#{p.position_y}  "}.join("")
  end

  # note that unlike Team.squad, this requires all players to have a FormationPo entry
  sig {returns(T.untyped)}
  def squad
    poss = positions_ordered.all
    {
      players: poss.map{|pos| pos.player.to_api},
      formation: poss.map{|pos| [pos.position_x, pos.position_y]}
    }
  end
end
