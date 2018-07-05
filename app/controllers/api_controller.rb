class ApiController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => [:save_formation]

  # () -> User | nil
  private def get_user
    User.joins(:sessions).where(sessions: {identifier: cookies[:session]}).first
  end

  private def get_team_json(id)
    team = Team.find(id)
    squad = team.squad
    {
      id: team.id,
      name: team.name,
      players: squad[:players],
      formation: squad[:formation]
    }
  end

  private def view_team_id(id)
    begin
      render json: get_team_json(id)
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

  def load_world
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

  private def game_event_to_json(e)
    {
      id: e.id,
      gameId: e.game_id,
      kind: e.kind,
      side: e.side,
      timestamp: e.time,
      message: e.message == nil ? '' : e.message,
      ballPos: [e.ball_pos_x, e.ball_pos_y]
    }
  end

  def game_events
    if get_user then
      game = Game.find(params[:id])
      game_events = GameEvent.where(game_id: game.id)
                             .order(:time)
                             .all
                             #.where('time >= ?', params[:from_time])
      render json: {
        id: game.id,
        homeTeam: get_team_json(game.home_team_id),
        awayTeam: get_team_json(game.away_team_id),
        start: game.start,
        events: game_events.map {|e| game_event_to_json(e)}
      }
    else
      head 403
    end
  end

  def game_events_since
    if get_user then
      game = Game.find(params[:id])
      if params[:event_id] == nil
        # get all game events
        game_events = GameEvent.where(game_id: game.id)
                               .order(:time)
                               .all
      else
        # get game events since the given event
        game_event = GameEvent.find(params[:event_id])
        game_events = GameEvent.where(game_id: game.id)
                               .where('time > ?', game_event.time)
                               .order(:time)
                               .all
      end
      render json: game_events.map {|e| game_event_to_json(e)}
    else
      head 403
    end
  end
end
