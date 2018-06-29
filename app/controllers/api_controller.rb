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

  private def load_league_record(league)
    teams = Team.joins(:team_leagues).where({team_leagues: {league_id: league.id}}).all
    {name: league.name, record: teams}
  end

  def league_tables
    render json: (League.order(:rank).all.map do |l|
      load_league_record l
    end)
  end
end
