class Game < ApplicationRecord
  belongs_to :league
  belongs_to :home_team, :class_name => 'Team'
  belongs_to :away_team, :class_name => 'Team'
  belongs_to :home_formation, :class_name => 'Formation', optional: true
  belongs_to :away_formation, :class_name => 'Formation', optional: true
  
  def attending
    Attendance.joins(:user).where(game: self).pluck("users.name")
  end

  def event_minutes(game_event)
    seconds = game_event.time - self.start

    if seconds < MatchSimHelper::MATCH_PERIODS[1][0] then
      mins = (seconds / 3).to_i
      mins <= 45 ? mins.to_s : "45+#{mins-45}"
    elsif seconds < MatchSimHelper::MATCH_PERIODS[2][0] then
      mins = (seconds / 3 - 10).to_i
      mins <= 90 ? mins.to_s : "90+#{mins-90}"
    elsif seconds < MatchSimHelper::MATCH_PERIODS[3][0] then
      mins = (seconds / 3 - 15).to_i
      mins <= 105 ? mins.to_s : "105+#{mins-105}"
    else
      mins = (seconds / 3 - 20).to_i
      mins <= 120 ? mins.to_s : "120+#{mins-120}"
    end
  end

  def simulate(until_time)
    simulator = MatchSimHelper::GameSimulator.new(self)
    simulator.simulate_until(until_time)
  end
end
