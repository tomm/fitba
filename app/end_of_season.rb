class EndOfSeason
  TEAMS_PROMOTED = 3  # and same number relegated, obviously

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
      return
    end

    last_season = DbHelper::SeasonHelper.current
    leagues = League.order(:rank).all
    # hash<league.rank,[team ids]>
    teams_in_league = (leagues.map {|l| [l.rank,[]]}).to_h

    leagues.each do |l|
      record = DbHelper::LeagueHelper.league_table(l.id, last_season)
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

      PopulateDbHelper::Populate.create_fixtures_for_league_season(leagueId, last_season + 1)
    end
  end
end
