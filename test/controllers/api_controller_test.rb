require 'test_helper'
#ActiveRecord::Base.logger = Logger.new(STDOUT)

class ApiControllerTest < ActionController::TestCase

  test "/load_game needs login" do
    get :load_game, :format => "json"
    assert_response 403
  end

  test "GET /load_game" do
    user = login
    get :load_game, :format => "json"
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal user.team_id, body['id']
    assert_equal "Test Utd", body['name']
  end

  test "/squad/:id needs login" do
    team = teams(:test_utd)
    get :view_team, { 'id' => team.id }, :format => "json"
    assert_response 403
  end

  test "GET /squad/:id" do
    login
    team = teams(:test_utd)
    get :view_team, { 'id' => team.id }, :format => "json"
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal team.id, body['id']
    assert_equal "Test Utd", body['name']
    # should return formation ordered positions 1-11
    assert_equal FORMATION_442, body['formation']
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
    login
    get :league_tables, :format => "json"
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "First Division", body[0]["name"]
    assert_equal "Second Division", body[1]["name"]
    assert_equal 3, body[0]["record"].size  # 3 teams in this league
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
  end

  test "GET /fixtures" do
    login
    get :fixtures, :format => "json"
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 5, body.size

    assert_equal "Played", body[0]["status"]
    assert_equal "2018-06-26T12:00:00.000Z", body[0]["start"]
    assert_equal "Test Utd", body[0]["homeName"]
    assert_equal "Test City", body[0]["awayName"]

    assert_equal "Played", body[1]["status"]
    assert_equal "2018-06-27T12:00:00.000Z", body[1]["start"]
    assert_equal "Test City", body[1]["homeName"]
    assert_equal "Test Utd", body[1]["awayName"]

    assert_equal "Scheduled", body[4]["status"]
  end

  test "POST /save_formation" do
    amy = players(:amy)
    barbara = players(:barbara)
    molly = players(:molly)  # not on our team
    FormationPo.destroy_all
    login

    # no formation now
    get :load_game, :format => "json"
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 0, body['formation'].size
    assert_equal 12, body['players'].size

    post :save_formation, [[amy.id, [1,2]], [barbara.id, [2,3]]].to_json, :format => "json"
    assert_response :success

    get :load_game, :format => "json"
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 2, body['formation'].size
    assert_equal 12, body['players'].size
    assert_equal "Amy", body['players'][0]['name']
    assert_equal "Barbara", body['players'][1]['name']
    assert_equal [1,2], body['formation'][0]
    assert_equal [2,3], body['formation'][1]

    # reorder amy & barbara. molly should be ignored because she is not on this team
    post :save_formation, [[barbara.id, [4,1]], [amy.id, [3,2], [molly.id, [2,3]]]].to_json, :format => "json"
    assert_response :success

    get :load_game, :format => "json"
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 2, body['formation'].size
    assert_equal 12, body['players'].size
    assert_equal "Barbara", body['players'][0]['name']
    assert_equal "Amy", body['players'][1]['name']
    assert_equal [4,1], body['formation'][0]
    assert_equal [3,2], body['formation'][1]
  end
end
