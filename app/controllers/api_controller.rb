class ApiController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => [:save_formation, :transfer_bid, :sell_player]

  # () -> User | nil
  private def get_user
    User.joins(:sessions).where(sessions: {identifier: cookies[:session]}).first
  end

  private def get_team_json(team)
    squad = team.squad
    {
      id: team.id,
      name: team.name,
      players: squad[:players],
      formation: squad[:formation]
    }
  end

  private def view_team_id(user, team_id)
    begin
      team = Team.find(team_id)
      r = get_team_json(team)
      if user.team_id == team_id
        r[:money] = team.money
      end
      render json: r
    rescue ActiveRecord::RecordNotFound
      head 404
    end
  end

  def view_team
    if user = get_user then
      view_team_id(user, params[:id])
    else
      head 403
    end
  end

  def load_world
    if user = get_user then
      view_team_id(user, user.team_id)
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
    season = SeasonHelper.current_season
    teams = Team.joins(:team_leagues).where({team_leagues: {league_id: league.id,
                                                            season: season}}).all
    {
      name: league.name,
      record: teams.map(&@@load_team_record)
    }
  }

  def league_tables
    if get_user then
      season = SeasonHelper::current_season
      leagues = League.order(:rank).all
      render json: (leagues.map do |l|
        {
          "name": l.name,
          "record": DbHelper::league_table(l.id, season)
        }
      end)
    else
      head 403
    end
  end

  def fixtures
    if user = get_user then
      season = SeasonHelper::current_season
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
    p = Player.where(id: e.player_id).first
    {
      id: e.id,
      gameId: e.game_id,
      kind: e.kind,
      side: e.side,
      timestamp: e.time,
      message: e.message == nil ? '' : e.message,
      ballPos: [e.ball_pos_x, e.ball_pos_y],
      playerName: if p then p.name else nil end
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
        homeTeam: get_team_json(Team.find(game.home_team_id)),
        awayTeam: get_team_json(Team.find(game.away_team_id)),
        start: game.start,
        status: game.status,
        homeGoals: game.home_goals,
        awayGoals: game.away_goals,
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
                               .where('time <= ?', Time.now)
                               .order(:time)
                               .all
      end
      render json: game_events.map {|e| game_event_to_json(e)}
    else
      head 403
    end
  end

  def transfer_listings
    if user = get_user then
      ts = TransferListing.order(:deadline).all.select do |t|
        # so slow and shit. want OR condition on query
        your_bid = TransferBid.where(team_id: user.team_id, transfer_listing_id: t.id).first
        # show active listings, or your listings, or listings you bid on
        (t.status == 'Active' and t.deadline > Time.now) or (your_bid != nil) or (t.team_id == user.team_id)
      end
      render json: (ts.map do |t|
        your_bid = TransferBid.where(team_id: user.team_id, transfer_listing_id: t.id).first
        status =
          if t.status == 'Active' then
            'OnSale'
          else
            if your_bid != nil then
              your_bid.status
            else
              t.status  # 'Sold' or 'Unsold'
            end
          end

        player = Player.find(t.player_id)

        {
          id: t.id,
          minPrice: t.min_price,
          deadline: t.deadline,
          sellerTeamId: t.team_id ? t.team_id : 0,
          status: status,
          youBid: your_bid == nil ? nil : your_bid.amount,
          player: player.to_api
        }
      end)
    else
      head 403
    end
  end

  def transfer_bid
    if user = get_user then
      data = JSON.parse(request.body.read())
      tid = data["transfer_listing_id"]
      transfer_listing = TransferListing.find(tid)
      if transfer_listing.deadline < Time.now then
        render json: {status: 'EXPIRED'}
      elsif data["amount"] == nil then
        TransferBid.where(team_id: user.team_id, transfer_listing_id: tid).destroy_all
        render json: {status: 'SUCCESS'}
      else
        your_bid = TransferBid.where(team_id: user.team_id, transfer_listing_id: tid).first
        if your_bid == nil then
          TransferBid.create(transfer_listing_id: tid, team_id: user.team_id, amount: data["amount"], status: "Pending")
          render json: {status: 'SUCCESS'}
        else
          your_bid.update(amount: data["amount"])
          render json: {status: 'SUCCESS'}
        end
      end
    else
      head 403
    end
  end

  def sell_player
    if user = get_user then
      data = JSON.parse(request.body.read())
      player_id = data["player_id"]
      player = Player.find_by(team_id: user.team_id, id: player_id)
      if player == nil then
        render json: {status: 'ERROR'}
      else
        TransferMarketHelper.list_player(player)
        render json: {status: 'SUCCESS'}
      end
    else
      head 403
    end
  end
end
