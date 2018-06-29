class FormationPo < ActiveRecord::Base
  belongs_to :formation
  belongs_to :player
end
