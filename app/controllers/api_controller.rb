# typed: true
class ApiController < ApplicationController
  before_action :require_login

  private def require_login
    @user = User.joins(:sessions).where(sessions: {identifier: cookies[:session]}).first
    if @user == nil then
      head 403
    end
  end

  private def get_team_json(team, override_squad: nil)
    if override_squad == nil then
      squad = team.squad
    else
      squad = override_squad
    end
    manager = User.where(team_id: team.id).first
    {
      id: team.id,
      name: team.name,
      players: squad[:players],
      formation: squad[:formation],
      manager: if manager != nil then manager.name else nil end,
      inbox: []
    }
  end

  def view_team
    render json: get_team_json(Team.find(params[:id]))
  rescue ActiveRecord::RecordNotFound
    head 404
  end

  def load_world
    team = Team.find(@user.team_id)
    team_json = get_team_json(team)
    team_json[:money] = team.money
    team_json[:inbox] = team.messages.order(:date).reverse_order.limit(100).map(&:to_api)

    render json: {
      season: SeasonHelper.current_season,
      team: team_json
    }
  rescue ActiveRecord::RecordNotFound
    head 404
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

  def history
    season = params[:season].to_i
    leagues = League.is_league.order(:rank).all
    cup_finalses = Game.where(season: season, stage: 1, status: 'Played').all
    render json: {
      season: season,
      cup_finals: cup_finalses.map(&:to_api),
      leagues: (leagues.map do |l|
        {
          "name": l.name,
          "record": DbHelper::league_table(l.id, season)
        }
      end)
    }
  end

  def league_tables
    season = SeasonHelper::current_season
    leagues = League.is_league.order(:rank).all
    render json: (leagues.map do |l|
      {
        "name": l.name,
        "record": DbHelper::league_table(l.id, season)
      }
    end)
  end

  def fixtures
    season = SeasonHelper::current_season
    games = Game.where(season: season).order(:start).all
    render json: games.map(&:to_api)
  end

  def save_formation
    # [[playerId: [positionX, positionY]]]
    data = JSON.parse(request.body.read())
    team = Team.find(@user.team_id)
    team.update_player_positions(data)
    render json: {status: 'SUCCESS'}
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
    game = Game.find(params[:id])
    game_events = GameEvent.where(game_id: game.id)
                           .order(:time)
                           .all
                           #.where('time >= ?', params[:from_time])
    # if the game has started then formations for each team exist referenced by the Game table,
    # otherwise use normal team formation
    home_squad = game.home_formation&.squad
    away_squad = game.away_formation&.squad
    render json: {
      id: game.id,
      homeTeam: get_team_json(game.home_team, override_squad: home_squad),
      awayTeam: get_team_json(game.away_team, override_squad: away_squad),
      start: game.start,
      status: game.status,
      stage: game.stage,
      homeGoals: game.home_goals,
      awayGoals: game.away_goals,
      homePenalties: game.home_penalties,
      awayPenalties: game.away_penalties,
      attending: game.attending,
      events: game_events.map {|e| game_event_to_json(e)}
    }
  end

  def game_events_since
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

    # remember this user 'attended' the live game
    if game.status == 'InProgress' then
      Attendance.find_or_create_by(game: game, user: @user)
    end

    render json: {
      attending: game.attending,
      events: game_events.map {|e| game_event_to_json(e)}
    }
  end

  def transfer_listings
    ts = TransferListing.order(:deadline).all.select do |t|
      # so slow and shit. want OR condition on query
      your_bid = TransferBid.where(team_id: @user.team_id, transfer_listing_id: t.id).first
      # show active listings, or your listings, or listings you bid on
      (t.status == 'Active' and t.deadline > Time.now) or (your_bid != nil) or (t.team_id == @user.team_id)
    end
    render json: (ts.map do |t|
      your_bid = TransferBid.where(team_id: @user.team_id, transfer_listing_id: t.id).first
      # count number of teams bidding
      num_bids = TransferBid.where(transfer_listing_id: t.id).select(:team_id).distinct.count

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
        sellerTeamName: t.team&.name,
        status: status,
        youBid: your_bid == nil ? nil : your_bid.amount,
        numBids: num_bids,
        player: player.to_api
      }
    end)
  end

  def transfer_bid
    data = JSON.parse(request.body.read())
    tid = data["transfer_listing_id"]
    transfer_listing = TransferListing.find(tid)
    if transfer_listing.deadline < Time.now then
      render json: {status: 'EXPIRED'}
    elsif data["amount"] == nil then
      TransferBid.where(team_id: @user.team_id, transfer_listing_id: tid).destroy_all
      render json: {status: 'SUCCESS'}
    else
      your_bid = TransferBid.where(team_id: @user.team_id, transfer_listing_id: tid).first
      if your_bid == nil then
        TransferBid.create(transfer_listing_id: tid, team_id: @user.team_id, amount: data["amount"], status: "Pending")
        render json: {status: 'SUCCESS'}
      else
        your_bid.update(amount: data["amount"])
        render json: {status: 'SUCCESS'}
      end
    end
  end

  def sell_player
    data = JSON.parse(request.body.read())
    player_id = data["player_id"]
    player = Player.find_by(team_id: @user.team_id, id: player_id)
    if player == nil then
      render json: {status: 'ERROR'}
    else
      TransferMarketHelper.list_player(player)
      render json: {status: 'SUCCESS'}
    end
  end

  def delete_message
    data = JSON.parse(request.body.read())
    message_id = data["message_id"]
    Message.where(team_id: @user.team_id, id: message_id).destroy_all
    render json: {status: 'SUCCESS'}
  end

  def got_fcm_token
    puts "Got fcm token #{params[:token]} for user #{@user.id}"
    begin
      UserFcmToken.create!(user: @user, token: params[:token])
    rescue ActiveRecord::RecordNotUnique
      # fine. already got token
    end
    head :no_content
  end

  def news_articles
    news = NewsArticle.order(:date).reverse_order.limit(10).all
    render json: news.map{|item|
      {
        id: item.id,
        title: item.title,
        body: item.body,
        date: item.date
      }
    }
  end

  def top_scorers
    season = if params[:season] then params[:season] else SeasonHelper.current_season end
    conn = ActiveRecord::Base.connection
    render json: League.is_league.order(:rank).all.map{|l|
      r = conn.execute("
    select 
      concat(p.forename,' ',p.name) as playername,

      (select array_to_string(array_agg(name), ', ') from teams where id in
        (select (case ge2.side when 0 then gm2.home_team_id else gm2.away_team_id end) as team_id
        from games gm2
        join game_events ge2 on ge2.game_id=gm2.id
        where ge2.player_id=p.id and ge2.kind = 'Goal' and
          gm2.season=#{conn.quote(season)} and gm2.league_id=#{conn.quote(l.id)}
      )) as teamname,

      (select count(*) from game_events ge
       join games g on g.id = ge.game_id
       where ge.player_id = p.id and ge.kind = 'Goal'
       and g.season=#{conn.quote(season)} and g.league_id=#{conn.quote(l.id)}) as goals
    from players p
    order by 3 desc
    limit 25
      ")

      { tournamentName: l.name, topScorers: r.to_a }
    }
  end

  def finances
    season = SeasonHelper.current_season

    conn = ActiveRecord::Base.connection

    season_items = conn.execute("
      select description,sum(amount) as amount from account_items
      where team_id=#{conn.quote(@user.team_id)} and season=#{conn.quote(season)}
        group by 1
    ")
    today_items = conn.execute("
      select description,sum(amount) as amount from account_items
      where team_id=#{conn.quote(@user.team_id)} and season=#{conn.quote(season)}
        and created_at::date = now()::date
        group by 1
    ")

    render json: {
      seasonItems: season_items.to_a,
      todayItems: today_items.to_a
    }
  end
end
