class Game < ApplicationRecord
  belongs_to :league
  belongs_to :home_team, :class_name => 'Team'
  belongs_to :away_team, :class_name => 'Team'
  belongs_to :home_formation, :class_name => 'Formation', optional: true
  belongs_to :away_formation, :class_name => 'Formation', optional: true

  def winner_loser
    if status == "Played" then
      if self.home_goals > self.away_goals then
        [self.home_team, self.away_team]
      elsif self.home_goals < self.away_goals then
        [self.away_team, self.home_team]
      elsif self.home_penalties > self.away_penalties then
        [self.home_team, self.away_team]
      elsif self.home_penalties < self.away_penalties then
        [self.away_team, self.home_team]
      else
        nil
      end
    else
      raise "Called winner_loser on game not yet played"
    end
  end

  def to_api
    {
      gameId: self.id,
      tournament: self.league.name,
      homeName: self.home_team.name,
      awayName: self.away_team.name,
      start: self.start,
      status: self.status,
      stage: self.stage,
      homeGoals: self.home_goals,
      awayGoals: self.away_goals,
      homePenalties: self.home_penalties,
      awayPenalties: self.away_penalties
    }
  end
  
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
