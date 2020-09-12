# typed: strict
class League < ApplicationRecord
  extend T::Sig

  # kind = League | Cup
  #
  scope :is_league, ->() { where(kind: "League") }
  scope :is_cup, ->() { where(kind: "Cup") }

  sig {returns(T::Array[Team])}
  def teams
    Team.joins(TeamLeague).where(league_id: self.id).all
  end
end
