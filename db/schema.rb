# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_08_18_201846) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "attendances", force: :cascade do |t|
    t.bigint "game_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id", "user_id"], name: "index_attendances_on_game_id_and_user_id", unique: true
    t.index ["game_id"], name: "index_attendances_on_game_id"
    t.index ["user_id"], name: "index_attendances_on_user_id"
  end

  create_table "formation_pos", id: :serial, force: :cascade do |t|
    t.integer "formation_id"
    t.integer "player_id"
    t.integer "position_num"
    t.integer "position_x"
    t.integer "position_y"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["formation_id"], name: "index_formation_pos_on_formation_id"
    t.index ["player_id"], name: "index_formation_pos_on_player_id"
  end

  create_table "formations", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "game_events", id: :serial, force: :cascade do |t|
    t.integer "game_id"
    t.datetime "time"
    t.text "message"
    t.integer "ball_pos_x"
    t.integer "ball_pos_y"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "kind"
    t.integer "side"
    t.integer "player_id"
    t.index ["game_id"], name: "index_game_events_on_game_id"
    t.index ["player_id"], name: "index_game_events_on_player_id"
  end

  create_table "games", id: :serial, force: :cascade do |t|
    t.integer "league_id"
    t.integer "home_team_id"
    t.integer "away_team_id"
    t.string "status"
    t.datetime "start"
    t.integer "home_goals"
    t.integer "away_goals"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "season"
    t.integer "home_formation_id"
    t.integer "away_formation_id"
    t.index ["away_team_id"], name: "index_games_on_away_team_id"
    t.index ["home_team_id"], name: "index_games_on_home_team_id"
    t.index ["league_id"], name: "index_games_on_league_id"
  end

  create_table "leagues", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "rank"
  end

  create_table "messages", id: :serial, force: :cascade do |t|
    t.integer "team_id", null: false
    t.string "from", null: false
    t.string "subject", null: false
    t.text "body", null: false
    t.datetime "date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id"], name: "index_messages_on_team_id"
  end

  create_table "news_articles", force: :cascade do |t|
    t.string "title", null: false
    t.string "body", null: false
    t.datetime "date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "players", id: :serial, force: :cascade do |t|
    t.integer "team_id"
    t.string "name", null: false
    t.integer "shooting", null: false
    t.integer "passing", null: false
    t.integer "tackling", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "handling", null: false
    t.integer "speed", null: false
    t.string "positions", null: false
    t.string "forename", null: false
    t.integer "age", null: false
    t.integer "injury", default: 0, null: false
    t.integer "form", default: 0, null: false
    t.index ["team_id"], name: "index_players_on_team_id"
  end

  create_table "sessions", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "identifier"
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "team_leagues", id: :serial, force: :cascade do |t|
    t.integer "team_id"
    t.integer "league_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "season"
    t.index ["league_id"], name: "index_team_leagues_on_league_id"
    t.index ["team_id"], name: "index_team_leagues_on_team_id"
  end

  create_table "teams", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "formation_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "money", default: 0, null: false
    t.integer "player_spawn_quality", default: 5, null: false
    t.index ["formation_id"], name: "index_teams_on_formation_id"
  end

  create_table "transfer_bids", id: :serial, force: :cascade do |t|
    t.integer "team_id"
    t.integer "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "transfer_listing_id"
    t.string "status", null: false
    t.index ["team_id"], name: "index_transfer_bids_on_team_id"
    t.index ["transfer_listing_id"], name: "index_transfer_bids_on_transfer_listing_id"
  end

  create_table "transfer_listings", id: :serial, force: :cascade do |t|
    t.integer "player_id"
    t.integer "min_price"
    t.datetime "deadline"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "team_id"
    t.string "status"
    t.index ["player_id"], name: "index_transfer_listings_on_player_id"
    t.index ["team_id"], name: "index_transfer_listings_on_team_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "team_id"
    t.string "secret"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id"], name: "index_users_on_team_id"
  end

  add_foreign_key "attendances", "games"
  add_foreign_key "attendances", "users"
  add_foreign_key "formation_pos", "formations"
  add_foreign_key "formation_pos", "players"
  add_foreign_key "game_events", "games"
  add_foreign_key "game_events", "players"
  add_foreign_key "games", "formations", column: "away_formation_id"
  add_foreign_key "games", "formations", column: "home_formation_id"
  add_foreign_key "games", "leagues"
  add_foreign_key "messages", "teams"
  add_foreign_key "players", "teams"
  add_foreign_key "sessions", "users"
  add_foreign_key "team_leagues", "leagues"
  add_foreign_key "team_leagues", "teams"
  add_foreign_key "teams", "formations"
  add_foreign_key "transfer_bids", "teams"
  add_foreign_key "transfer_bids", "transfer_listings"
  add_foreign_key "transfer_listings", "players"
  add_foreign_key "transfer_listings", "teams"
  add_foreign_key "users", "teams"
end
