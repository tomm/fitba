# typed: strict
class Game < ApplicationRecord
  extend T::Sig

  belongs_to :league
  belongs_to :home_team, :class_name => 'Team'
  belongs_to :away_team, :class_name => 'Team'
  belongs_to :home_formation, :class_name => 'Formation', optional: true
  belongs_to :away_formation, :class_name => 'Formation', optional: true

  sig {params(time: ActiveSupport::TimeWithZone).returns(String)}
  def time_to_match_minutes(time)
    # seconds
    s = (time - self.start).to_i

    if s < 3*55 then
      mins = s/3
      if mins <= 45 then mins.to_s else "45+" + (mins-45).to_s end
    elsif s < 3*105 then
      mins = (s/3 - 10)
      if mins <= 90 then mins.to_s else "90+" + (mins-90).to_s end
    elsif s < 3*125 then
      mins = (s/3 - 15)
      if mins <= 105 then mins.to_s else "105+" + (mins-105).to_s end
    else
      mins = (s/3 - 20)
      if mins <= 120 then mins.to_s else "120+" + (mins-120).to_s end
    end
  end

  sig {params(side: Integer).returns(Integer)}
  def subs_used(side)
    if side == 0 then self.home_subs else self.away_subs end
  end

  sig {params(side: Integer).void}
  def use_sub(side)
    if side == 0 then self.home_subs += 1 else self.away_subs += 1 end
  end

  sig {returns(T.any(NilClass, [Team,Team]))}
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

  sig {returns(T.untyped)}
  def to_api
    {
      gameId: self.id,
      tournament: self.league.name,
      homeTeamId: self.home_team.id,
      awayTeamId: self.away_team.id,
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
  
  sig {returns(T::Array[String])}
  def attending
    Attendance.joins(:user).where(game: self).pluck("users.name")
  end

  sig {params(game_event: GameEvent).returns(String)}
  def event_minutes(game_event)
    seconds = (game_event.time - self.start).to_f

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

  sig {params(until_time: Time).void}
  def simulate(until_time)
    simulator = MatchSimHelper::GameSimulator.new(self)
    simulator.simulate_until(until_time)
  end
end
