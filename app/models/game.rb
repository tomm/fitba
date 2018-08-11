class Game < ActiveRecord::Base
  belongs_to :league
  belongs_to :home_team, :class_name => 'Team'
  belongs_to :away_team, :class_name => 'Team'
  belongs_to :home_formation, :class_name => 'Formation'
  belongs_to :away_formation, :class_name => 'Formation'
  
  def event_minutes(game_event)
    (90 * (game_event.time - self.start) / MatchSimHelper::MATCH_LENGTH_SECONDS).to_i
  end

  def simulate(until_time)
    simulator = MatchSimHelper::GameSimulator.new(self)
    simulator.simulate_until(until_time)
  end
end
