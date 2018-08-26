require 'test_helper'
#ActiveRecord::Base.logger = Logger.new(STDOUT)

class ApiControllerTest < ActionController::TestCase

  test "/load_world needs login" do
    get :load_world, :format => "json"
    assert_response 403
  end

  test "GET /load_world" do
    user = login
    get :load_world, :format => "json"
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal user.team_id, body['id']
    assert_equal "Test Utd", body['name']
    assert_equal 12345, body['money']
    assert_equal "Tom", body['manager']
  end

  test "team_messages" do
    user = login

    get :load_world, :format => "json"
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal [], body['inbox']

    Message.send_message(user.team, "Bob", "Hello", "Hello old bean", Time.now)

    get :load_world, :format => "json"
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "Hello", body['inbox'][0]['subject']

    post :delete_message, body: {message_id: body['inbox'][0]['id']}.to_json, :format => "json"
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "SUCCESS", body['status']

    get :load_world, :format => "json"
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal [], body['inbox']
  end

  test "/sell_player" do
    login

    get :transfer_listings, :format => "json"
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 0, body.size

    post :sell_player, body: {player_id: players(:carla).id}.to_json, :format => "json"
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "SUCCESS", body['status']

    get :transfer_listings, :format => "json"
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body.size

    # idempotent
    post :sell_player, body: {player_id: players(:carla).id}.to_json, :format => "json"
    assert_response :success

    get :transfer_listings, :format => "json"
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body.size

    # not our player
    post :sell_player, body: {player_id: players(:zuzana).id}.to_json, :format => "json"
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "ERROR", body['status']
  end

  test "transfer_market_sold" do
    TransferListing.delete_all
    tl = TransferListing.create(player_id: players(:molly).id, min_price: 123,
                           status: 'Active', team_id: teams(:test_city).id,
                           deadline: Time.now+60)
    tid = tl.id
    login
    post :transfer_bid, body: {amount: 200, transfer_listing_id: tid}.to_json, :format => "json"
    assert_response :success

    tl.update(deadline: Time.now-60)
    TransferMarketHelper.decide_transfer_market_bids()

    get :transfer_listings, :format => "json"
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body.size
    assert_equal 123, body[0]["minPrice"]
    assert_equal 200, body[0]["youBid"]
    assert_equal "YouWon", body[0]["status"]

    # should be deleted once over a day old
    tl.update(deadline: Time.now-60*60*25)
    TransferMarketHelper.decide_transfer_market_bids()

    get :transfer_listings, :format => "json"
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 0, body.size
  end

  test "cant_sell_injured_players" do
    login
    TransferListing.delete_all
    tl = TransferListing.create(player_id: players(:amy).id, min_price: 123,
                           status: 'Active', team_id: teams(:test_utd).id,
                           deadline: Time.now+60)
    players(:amy).update(injury: 10)
    tid = tl.id

    tl.update(deadline: Time.now-60)
    TransferMarketHelper.decide_transfer_market_bids()

    get :transfer_listings, :format => "json"
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body.size
    assert_equal "Unsold", body[0]["status"]
  end

  test "transfer_listing_from_no_team" do
    TransferListing.delete_all
    pl1 = Player.random(1)
    pl1.save
    pl2 = Player.random(1)
    pl2.save
    tl1 = TransferListing.create(player_id: pl1.id, min_price: 123, status: 'Active', team_id: nil, deadline: Time.now+60)
    tl2 = TransferListing.create(player_id: pl2.id, min_price: 123, status: 'Active', team_id: nil, deadline: Time.now+60)
    login

    post :transfer_bid, body: {amount: 200, transfer_listing_id: tl1.id}.to_json, :format => "json"
    assert_response :success

    tl1.update(deadline: Time.now-60)
    tl2.update(deadline: Time.now-60)
    TransferMarketHelper.decide_transfer_market_bids()

    get :transfer_listings, :format => "json"
    assert_response :success
    body = JSON.parse(response.body)
    # doesn't show expired listings that we didn't bid on
    assert_equal 1, body.size
    assert_equal "YouWon", body[0]["status"]
  end

  test "transfer_market" do
    TransferListing.delete_all
    tl = TransferListing.create(player_id: players(:molly).id, min_price: 123,
                           status: 'Active', team_id: teams(:test_city).id,
                           deadline: Time.now+60)
    tid = tl.id
    login

    get :transfer_listings, :format => "json"
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body.size
    assert_equal 123, body[0]["minPrice"]
    assert_nil body[0]["youBid"]
    assert_equal "OnSale", body[0]["status"]

    post :transfer_bid, body: {amount: 200, transfer_listing_id: tid}.to_json, :format => "json"
    assert_response :success

    get :transfer_listings, :format => "json"
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body.size
    assert_equal 123, body[0]["minPrice"]
    assert_equal 200, body[0]["youBid"]
    assert_equal "OnSale", body[0]["status"]
    
    post :transfer_bid, body: {amount: 300, transfer_listing_id: tid}.to_json, :format => "json"
    assert_response :success

    get :transfer_listings, :format => "json"
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body.size
    assert_equal 123, body[0]["minPrice"]
    assert_equal 300, body[0]["youBid"]
    assert_equal "OnSale", body[0]["status"]
    
    post :transfer_bid, body: {amount: nil, transfer_listing_id: tid}.to_json, :format => "json"
    assert_response :success

    get :transfer_listings, :format => "json"
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body.size
    assert_equal 123, body[0]["minPrice"]
    assert_nil body[0]["youBid"]
    assert_equal "OnSale", body[0]["status"]

    tl.update(deadline: Time.now-60)
    TransferMarketHelper.decide_transfer_market_bids()

    get :transfer_listings, :format => "json"
    assert_response :success
    body = JSON.parse(response.body)
    # doesn't show expired listings that we didn't bid on
    assert_equal 0, body.size

    # always sells (even without any bids)
    tl = TransferListing.find(tid)
    assert_equal "Sold", tl.status
  end

  test "/squad/:id needs login" do
    team = teams(:test_utd)
    get :view_team, params: { 'id' => team.id }, :format => "json"
    assert_response 403
  end

  test "GET /squad/:id" do
    login
    team = teams(:test_utd)
    get :view_team, params: { 'id' => team.id }, :format => "json"
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal team.id, body['id']
    assert_equal "Test Utd", body['name']
    # should return formation ordered positions 1-11
    assert_equal AiManagerHelper::FORMATION_442, body['formation']
    # should return players ordered 1-11, then reserves
    assert_equal "Amy", body['players'][0]['name'] # GK
    assert_equal 2, body['players'][0]['shooting']
    assert_equal 3, body['players'][0]['passing']
    assert_equal 4, body['players'][0]['tackling']
    assert_equal 5, body['players'][0]['handling']
    assert_equal 6, body['players'][0]['speed']
    assert_equal "Katherine", body['players'][10]['name']  # CF
    assert_equal "Lena", body['players'][11]['name']  # reserve
  end

  test "GET /tables" do
    test_utd = teams(:test_utd)
    test_city = teams(:test_city)
    test_team4 = teams(:test_team4)
    test_athletico = teams(:test_athletico)
    login
    get :league_tables, :format => "json"
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "First Division", body[0]["name"]
    assert_equal "Second Division", body[1]["name"]
    assert_equal 4, body[0]["record"].size  # 4 teams in this league
    assert_equal 4, body[1]["record"].size  # 4 teams in this league
    assert_equal "Test City", body[0]["record"][0]["name"]
    assert_equal test_city.id, body[0]["record"][0]["teamId"]
    assert_equal 1, body[0]["record"][0]["won"]
    assert_equal 1, body[0]["record"][0]["drawn"]
    assert_equal 1, body[0]["record"][0]["lost"]
    assert_equal 4, body[0]["record"][0]["goalsFor"]
    assert_equal 3, body[0]["record"][0]["goalsAgainst"]
    assert_equal test_utd.id, body[0]["record"][1]["teamId"]
    assert_equal "Test Utd", body[0]["record"][1]["name"]
    assert_equal 1, body[0]["record"][1]["won"]
    assert_equal 1, body[0]["record"][1]["drawn"]
    assert_equal 1, body[0]["record"][1]["lost"]
    assert_equal 3, body[0]["record"][1]["goalsFor"]
    assert_equal 4, body[0]["record"][1]["goalsAgainst"]
    assert_equal test_team4.id, body[0]["record"][2]["teamId"]
    assert_equal "Test Team4", body[0]["record"][2]["name"]
    assert_equal 0, body[0]["record"][2]["won"]
    assert_equal 2, body[0]["record"][2]["drawn"]
    assert_equal 0, body[0]["record"][2]["lost"]
    assert_equal 2, body[0]["record"][2]["goalsFor"]
    assert_equal 2, body[0]["record"][2]["goalsAgainst"]
    assert_equal test_athletico.id, body[0]["record"][3]["teamId"]
    assert_equal "Test Athletico", body[0]["record"][3]["name"]
    assert_equal 0, body[0]["record"][3]["won"]
    assert_equal 0, body[0]["record"][3]["drawn"]
    assert_equal 0, body[0]["record"][3]["lost"]
    assert_equal 0, body[0]["record"][3]["goalsFor"]
    assert_equal 0, body[0]["record"][3]["goalsAgainst"]
  end

  test "GET /fixtures" do
    login
    get :fixtures, :format => "json"
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 6, body.size

    assert_equal "Played", body[0]["status"]
    assert_equal "2018-06-26T12:00:00.000Z", body[0]["start"]
    assert_equal "Test Utd", body[0]["homeName"]
    assert_equal "Test City", body[0]["awayName"]

    assert_equal "Played", body[1]["status"]
    assert_equal "2018-06-27T12:00:00.000Z", body[1]["start"]
    assert_equal "Test City", body[1]["homeName"]
    assert_equal "Test Utd", body[1]["awayName"]

    assert_equal "Played", body[2]["status"]
    assert_equal "Played", body[3]["status"]
    assert_equal "InProgress", body[4]["status"]
    assert_equal "Scheduled", body[5]["status"]
  end

  test "GET api#game_events" do
    game = games(:in_progress_game)
    assert_equal "InProgress", game.status

    login
    get :game_events, params: { 'id' => game.id }, :format => "json"
    assert_response :success
    body = JSON.parse(response.body)

    assert_equal game.id, body['id']
    assert_equal game.start, body['start']
    # XXX could test whole team structure here...
    assert_equal game.home_team_id, body['homeTeam']['id']
    assert_equal game.away_team_id, body['awayTeam']['id']
    assert_equal 4, body['events'].size
    assert_equal ({
      'id' => game_events(:one).id,
      'gameId' => game.id,
      'kind' => 'KickOff',
      'side' => 0,
      'timestamp' => game.start.to_json.tr('"',''),
      'message' => 'Kick off!',
      'playerName' => nil,
      'ballPos' => [2,3]
    }), body['events'][0]
    assert_equal game.start + 1, body['events'][1]['timestamp']
    assert_equal game.start + 2, body['events'][2]['timestamp']
    assert_equal game.start + 3, body['events'][3]['timestamp']
  end

  test "GET api#game_events_since" do
    user = users(:user_tom)
    game = games(:in_progress_game)
    assert_equal "InProgress", game.status

    Attendance.create(game: game, user: user)

    login

    get :game_events_since, params: { 'id' => game.id, }, :format => "json"
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal ["Tom"], body['attending']
    assert_equal 4, body['events'].size
    assert_equal game_events(:one).id, body['events'][0]['id']
    assert_equal game_events(:two).id, body['events'][1]['id']
    assert_equal game_events(:three).id, body['events'][2]['id']
    assert_equal game_events(:four).id, body['events'][3]['id']

    get :game_events_since, params: { 'id' => game.id, 'event_id' => body['events'][0]['id'] }, :format => "json"
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 3, body['events'].size
    assert_equal game_events(:two).id, body['events'][0]['id']
    assert_equal game_events(:three).id, body['events'][1]['id']
    assert_equal game_events(:four).id, body['events'][2]['id']
  end

  test "POST /save_formation" do
    amy = players(:amy)
    barbara = players(:barbara)
    molly = players(:molly)  # not on our team
    FormationPo.destroy_all
    login

    # default formation (442)
    get :load_world, :format => "json"
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal AiManagerHelper::FORMATION_442, body['formation']
    assert_equal 12, body['players'].size

    post :save_formation, body: [[amy.id, [1,2]], [barbara.id, [2,3]]].to_json, :format => "json"
    assert_response :success

    expected_formation = [[1, 2], [2, 3], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0]]
    expected_formation[0] = [1,2]
    expected_formation[1] = [2,3]
    get :load_world, :format => "json"
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal expected_formation, body['formation']
    assert_equal 12, body['players'].size
    assert_equal "Amy", body['players'][0]['name']
    assert_equal "Barbara", body['players'][1]['name']
    assert_equal [1,2], body['formation'][0]
    assert_equal [2,3], body['formation'][1]

    # reorder amy & barbara. molly should be ignored because she is not on this team
    post :save_formation, body: [[barbara.id, [4,1]], [amy.id, [3,2], [molly.id, [2,3]]]].to_json, :format => "json"
    assert_response :success

    get :load_world, :format => "json"
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 11, body['formation'].size
    assert_equal 12, body['players'].size
    assert_equal "Barbara", body['players'][0]['name']
    assert_equal "Amy", body['players'][1]['name']
    assert_equal [4,1], body['formation'][0]
    assert_equal [3,2], body['formation'][1]
  end

  test "news_articles" do
    login
    get :news_articles, :format => 'json'
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body.size
    assert_equal "Stuff happened!", body[0]['title']
    assert_equal "Oh yeah", body[0]['body']
    assert (body[0].include? 'date')
  end

  test "top_scorers" do
    login
    get :top_scorers, :format => 'json'
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "First Division", body[0]['tournamentName']
    assert_equal "Second Division", body[1]['tournamentName']
  end
end
