class ApiController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => [:save_formation]

  # () -> User | nil
  private def get_user
    User.joins(:sessions).where(sessions: {identifier: cookies[:session]}).first
  end

  private def view_team_id(id)
    begin
      team = Team.find(id)
      squad = team.squad
      render json: {
        id: team.id,
        name: team.name,
        players: squad[:players],
        formation: squad[:formation]
      }
    rescue ActiveRecord::RecordNotFound
      head 403
    end
  end

  def view_team
    if get_user then
      view_team_id(params[:id])
    else
      head 403
    end
  end

  def load_game
    if user = get_user then
      view_team_id(user.team_id)
    else
      head 403
    end
  end

  @@load_team_record = lambda {|team|
    {
      teamId: team.id,
      name: team.name,
      played: 0,
      won: 0,
      drawn: 0,
      lost: 0,
      goalsFor: 0,
      goalsAgainst: 0
    }
  }

  @@load_league_record = lambda {|league|
    season = DbHelper::Season.current
    teams = Team.joins(:team_leagues).where({team_leagues: {league_id: league.id,
                                                            season: season}}).all
    {
      name: league.name,
      record: teams.map(&@@load_team_record)
    }
  }

  def league_tables
    if get_user then
      season = DbHelper::SeasonHelper.current
      leagues = League.order(:rank).all
      render json: (leagues.map do |l|
        {
          "name": l.name,
          "record": DbHelper::LeagueHelper.league_table(l.id, season)
        }
      end)
    else
      head 403
    end
  end

  def fixtures
    if user = get_user then
      season = DbHelper::SeasonHelper.current
      team_league = TeamLeague.find_by(team_id: user.team_id)
      games = Game.where(league_id: team_league.league_id, season: season).order(:start).all
      render json: (games.map do |g|
        t1 = Team.find(g.home_team_id)
        t2 = Team.find(g.away_team_id)
        {
          gameId: g.id,
          homeName: t1.name,
          awayName: t2.name,
          start: g.start,
          status: g.status,
          homeGoals: g.home_goals,
          awayGoals: g.away_goals
        }
      end)
    else
      head 403
    end
  end

  def save_formation
    if user = get_user then
      # [[playerId: [positionX, positionY]]]
      data = JSON.parse(request.body.read())
      team = Team.find(user.team_id)
      team.update_player_positions(data)
      render json: {status: 'SUCCESS'}
    else
      head 403
    end
  end
end
