class League < ApplicationRecord
  # kind = League | Cup
  #
  scope :is_league, ->() { where(kind: "League") }
  scope :is_cup, ->() { where(kind: "Cup") }

  # () -> [Team]
  def teams
    Team.join(TeamLeague).where(league_id: self.id).all
  end
end
