class League < ActiveRecord::Base
  # () -> [Team]
  def teams
    Team.join(TeamLeague).where(league_id: self.id).all
  end
end
