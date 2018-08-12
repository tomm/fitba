class Formation < ActiveRecord::Base
  has_many :formation_pos

  def positions_ordered
    FormationPo.where(formation_id: self.id).order(:position_num)
  end

  def to_s
    "Formation " + positions_ordered.map{|p| "#{p.player.name}:#{p.position_x},#{p.position_y}  "}.join("")
  end
end
