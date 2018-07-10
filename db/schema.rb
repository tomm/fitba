# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20180710102229) do

  create_table "formation_pos", force: :cascade do |t|
    t.integer  "formation_id"
    t.integer  "player_id"
    t.integer  "position_num"
    t.integer  "position_x"
    t.integer  "position_y"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "formation_pos", ["formation_id"], name: "index_formation_pos_on_formation_id"
  add_index "formation_pos", ["player_id"], name: "index_formation_pos_on_player_id"

  create_table "formations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "game_events", force: :cascade do |t|
    t.integer  "game_id"
    t.datetime "time"
    t.text     "message"
    t.integer  "ball_pos_x"
    t.integer  "ball_pos_y"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "kind"
    t.integer  "side"
  end

  add_index "game_events", ["game_id"], name: "index_game_events_on_game_id"

  create_table "games", force: :cascade do |t|
    t.integer  "league_id"
    t.integer  "home_team_id"
    t.integer  "away_team_id"
    t.string   "status"
    t.datetime "start"
    t.integer  "home_goals"
    t.integer  "away_goals"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.integer  "season"
  end

  add_index "games", ["away_team_id"], name: "index_games_on_away_team_id"
  add_index "games", ["home_team_id"], name: "index_games_on_home_team_id"
  add_index "games", ["league_id"], name: "index_games_on_league_id"

  create_table "leagues", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.integer  "rank"
    t.boolean  "is_finished"
  end

  create_table "players", force: :cascade do |t|
    t.integer  "team_id"
    t.string   "name"
    t.integer  "shooting"
    t.integer  "passing"
    t.integer  "tackling"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "handling"
    t.integer  "speed"
  end

  add_index "players", ["team_id"], name: "index_players_on_team_id"

  create_table "sessions", force: :cascade do |t|
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "identifier"
  end

  add_index "sessions", ["user_id"], name: "index_sessions_on_user_id"

  create_table "team_leagues", force: :cascade do |t|
    t.integer  "team_id"
    t.integer  "league_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "season"
  end

  add_index "team_leagues", ["league_id"], name: "index_team_leagues_on_league_id"
  add_index "team_leagues", ["team_id"], name: "index_team_leagues_on_team_id"

  create_table "teams", force: :cascade do |t|
    t.string   "name"
    t.integer  "formation_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "teams", ["formation_id"], name: "index_teams_on_formation_id"

  create_table "transfer_bids", force: :cascade do |t|
    t.integer  "team_id"
    t.integer  "amount"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.integer  "transfer_listing_id"
  end

  add_index "transfer_bids", ["team_id"], name: "index_transfer_bids_on_team_id"
  add_index "transfer_bids", ["transfer_listing_id"], name: "index_transfer_bids_on_transfer_listing_id"

  create_table "transfer_listings", force: :cascade do |t|
    t.integer  "player_id"
    t.integer  "min_price"
    t.date     "deadline"
    t.string   "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "transfer_listings", ["player_id"], name: "index_transfer_listings_on_player_id"

  create_table "users", force: :cascade do |t|
    t.string   "name"
    t.integer  "team_id"
    t.string   "secret"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "users", ["team_id"], name: "index_users_on_team_id"

end
