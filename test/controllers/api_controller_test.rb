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
    assert_equal [2,6], body['formation'][0]
    assert_equal [3,1], body['formation'][10]
    # should return players ordered 1-11, then reserves
    assert_equal "Amy", body['players'][0]['name'] # GK
    assert_equal "Katherine", body['players'][10]['name']  # CF
    assert_equal "Lena", body['players'][11]['name']  # reserve
  end

  test "GET /tables" do
    get :league_tables, :format => "json"
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "First Division", body[0]["name"]
    assert_equal "Second Division", body[1]["name"]
  end
end
