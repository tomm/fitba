class ApiController < ApplicationController

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

  private def get_user
    User.joins(:sessions).where(sessions: {identifier: cookies[:session]}).first
  end

  def load_game
    if user = get_user then
      view_team_id(user.team_id)
    else
      head 403
    end
  end

  private def load_team_record(team)
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
  end

  private def load_league_record(league)
    teams = Team.joins(:team_leagues).where({team_leagues: {league_id: league.id}}).all
    {
      name: league.name,
      record: teams.map {|t| load_team_record t}
    }
  end

  def league_tables
    if get_user then
      render json: (League.order(:rank).all.map do |l|
        load_league_record l
      end)
    else
      head 403
    end
  end

  def fixtures
    if user = get_user then
      team_league = TeamLeague.find_by(team_id: user.team_id)
      games = Game.where(league_id: team_league.league_id).order(:start).all
      render json: (games.map do |g|
        t1 = Team.find(g.home_team_id)
        t2 = Team.find(g.away_team_id)
        {
          gameId: g.id,
          homeName: t1.name,
          awayName: t2.name,
          start: g.start,
          status: g.status
        }
      end)
    else
      head 403
    end
  end
end
