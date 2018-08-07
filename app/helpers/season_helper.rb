module SeasonHelper
  TEAMS_PROMOTED = 3  # and same number relegated, obviously

  # () -> int
  def self.current_season
    r = ActiveRecord::Base.connection.execute("select max(season) as max from games")
    raise "No fixtures exist!" unless r.present?
    r[0]["max"].to_i
  end

  #: () -> Bool
  def self.is_end_of_season?
    Game.where.not(status: 'Played').count == 0
  end

  #: () -> Date
  def self.last_game_date
    time = Game.order(:start).reverse_order.pluck(:start).first
    Date.new(time.year, time.month, time.day)
  end

  #: ()
  def self.create_new_season
    if not is_end_of_season? then
      p "Warning: Called create_new_season even though the season is not finished. Doing it anyway..."
    end

    last_season = current_season
    leagues = League.order(:rank).all
    # hash<league.rank,[team ids]>
    teams_in_league = (leagues.map {|l| [l.rank,[]]}).to_h

    leagues.each do |l|
      record = DbHelper::league_table(l.id, last_season)
      #staying in
      can_promote = teams_in_league.key?(l.rank-1)
      can_relegate = teams_in_league.key?(l.rank+1)

      raise "League too small (#{record.size} teams) for promotion/relegation zone size #{TEAMS_PROMOTED}" \
        unless record.size >= (can_promote ? TEAMS_PROMOTED : 0) + (can_relegate ? TEAMS_PROMOTED : 0)

      teamIds = record.map {|r| r[:teamId]}

      if can_promote then
        teams_in_league[l.rank-1].concat(teamIds.slice!(0, TEAMS_PROMOTED))
      end
      if can_relegate then
        teams_in_league[l.rank+1].concat(teamIds.slice!(teamIds.size - TEAMS_PROMOTED, teamIds.size))
      end

      teams_in_league[l.rank].concat(teamIds)
    end

    teams_in_league.each do |rank, teamIds|
      leagueId = League.where(rank: rank).pluck(:id).first
      teamIds.each do |teamId|
        TeamLeague.create(team_id: teamId, league_id: leagueId, season: last_season + 1)
      end

      create_fixtures_for_league_season(leagueId, last_season + 1)
    end
  end

  def self.create_fixtures_for_league_season(league_id, season)
    teams = Team.in_league_season(league_id, season).all
    raise "No teams in league!" unless teams.size > 0

    now = Time.now
    # create fixtures starting tomorrow
    season_start = Time.new(now.year, now.month, now.day) + 24*3600
    next_start = season_start
    time_slots = [10*3600, 12*3600, 14*3600,
                  16*3600, 18*3600, 20*3600]

    to_play = teams.permutation(2).to_a.shuffle

    # this won't terminate if time_slots.size > teams.size/2
    #raise "Too many time slots for number of teams!" unless time_slots.size <= teams.size/2
    # find time_slots.size number of games per 'day', that only include each team once
    days = []
    while to_play.size > 0 do
      day = []
      tid_today = []
      while day.size < time_slots.size and to_play.size > 0 do
        good = to_play.find {|c| (not tid_today.include?(c[0].id)) and (not tid_today.include?(c[1].id))}
        if good == nil then
          #puts "Only filled #{day.size}/#{time_slots.size} slots today"
          break
        end
        to_play.delete(good)
        day << good 
        tid_today << good[0].id
        tid_today << good[1].id
      end
      days << day
    end

    days.each do |d|
      d.each_with_index do |match,slot|
        Game.create(league_id: league_id, home_team: match[0], away_team: match[1],
                     status: "Scheduled",
                     start: next_start + time_slots[slot],
                     home_goals: 0, away_goals: 0,
                     season: season)
      end
      next_start += 24*3600
    end
    #puts "League fixtues run from #{season_start.to_s} to #{next_start}"
  end
end
