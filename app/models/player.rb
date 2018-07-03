class Player < ActiveRecord::Base
  belongs_to :team
  has_many :formation_pos

  def skill
    shooting + passing + tackling + handling + speed
  end
end
