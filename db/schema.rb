# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_01_16_034249) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "head_to_head_records", force: :cascade do |t|
    t.bigint "manager_id", null: false
    t.bigint "opponent_manager_id", null: false
    t.bigint "league_id", null: false
    t.integer "regular_season_wins", default: 0
    t.integer "regular_season_losses", default: 0
    t.integer "regular_season_ties", default: 0
    t.integer "playoff_wins", default: 0
    t.integer "playoff_losses", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["league_id"], name: "index_head_to_head_records_on_league_id"
    t.index ["manager_id", "opponent_manager_id", "league_id"], name: "idx_h2h_manager_opponent_league", unique: true
    t.index ["manager_id"], name: "index_head_to_head_records_on_manager_id"
    t.index ["opponent_manager_id"], name: "index_head_to_head_records_on_opponent_manager_id"
  end

  create_table "leagues", force: :cascade do |t|
    t.string "name"
    t.string "yahoo_league_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "lifetime_records", force: :cascade do |t|
    t.bigint "manager_id", null: false
    t.bigint "league_id", null: false
    t.integer "regular_season_wins", default: 0
    t.integer "regular_season_losses", default: 0
    t.integer "regular_season_ties", default: 0
    t.integer "playoff_wins", default: 0
    t.integer "playoff_losses", default: 0
    t.integer "championships_won", default: 0
    t.integer "championships_lost", default: 0
    t.decimal "total_points_for", precision: 10, scale: 2, default: "0.0"
    t.decimal "total_points_against", precision: 10, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["league_id"], name: "index_lifetime_records_on_league_id"
    t.index ["manager_id", "league_id"], name: "index_lifetime_records_on_manager_id_and_league_id", unique: true
    t.index ["manager_id"], name: "index_lifetime_records_on_manager_id"
  end

  create_table "managers", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "yahoo_guid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["yahoo_guid"], name: "index_managers_on_yahoo_guid", unique: true
  end

  create_table "matchup_players", force: :cascade do |t|
    t.bigint "matchup_id", null: false
    t.bigint "team_id", null: false
    t.string "yahoo_player_key"
    t.string "player_name"
    t.string "position"
    t.decimal "points", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["matchup_id", "team_id", "yahoo_player_key"], name: "idx_matchup_players_unique", unique: true
    t.index ["matchup_id"], name: "index_matchup_players_on_matchup_id"
    t.index ["team_id"], name: "index_matchup_players_on_team_id"
  end

  create_table "matchups", force: :cascade do |t|
    t.bigint "season_id", null: false
    t.integer "week"
    t.string "yahoo_matchup_key"
    t.bigint "team_1_id", null: false
    t.bigint "team_2_id", null: false
    t.decimal "team_1_score", precision: 10, scale: 2
    t.decimal "team_2_score", precision: 10, scale: 2
    t.bigint "winner_id"
    t.integer "matchup_type", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["season_id", "week"], name: "index_matchups_on_season_id_and_week"
    t.index ["season_id"], name: "index_matchups_on_season_id"
    t.index ["team_1_id"], name: "index_matchups_on_team_1_id"
    t.index ["team_2_id"], name: "index_matchups_on_team_2_id"
    t.index ["winner_id"], name: "index_matchups_on_winner_id"
  end

  create_table "seasons", force: :cascade do |t|
    t.bigint "league_id", null: false
    t.integer "year"
    t.string "yahoo_league_key"
    t.string "yahoo_game_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["league_id"], name: "index_seasons_on_league_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.string "session_id"
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
  end

  create_table "standings", force: :cascade do |t|
    t.bigint "season_id", null: false
    t.bigint "team_id", null: false
    t.integer "rank"
    t.integer "wins", default: 0
    t.integer "losses", default: 0
    t.integer "ties", default: 0
    t.decimal "points_for", precision: 10, scale: 2, default: "0.0"
    t.decimal "points_against", precision: 10, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["season_id", "team_id"], name: "index_standings_on_season_id_and_team_id", unique: true
    t.index ["season_id"], name: "index_standings_on_season_id"
    t.index ["team_id"], name: "index_standings_on_team_id"
  end

  create_table "teams", force: :cascade do |t|
    t.bigint "season_id", null: false
    t.bigint "manager_id", null: false
    t.string "yahoo_team_key"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["manager_id"], name: "index_teams_on_manager_id"
    t.index ["season_id"], name: "index_teams_on_season_id"
    t.index ["yahoo_team_key"], name: "index_teams_on_yahoo_team_key", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "yahoo_uid"
    t.text "access_token"
    t.text "refresh_token"
    t.datetime "token_expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["yahoo_uid"], name: "index_users_on_yahoo_uid", unique: true
  end

  add_foreign_key "head_to_head_records", "leagues"
  add_foreign_key "head_to_head_records", "managers"
  add_foreign_key "head_to_head_records", "managers", column: "opponent_manager_id"
  add_foreign_key "lifetime_records", "leagues"
  add_foreign_key "lifetime_records", "managers"
  add_foreign_key "matchup_players", "matchups"
  add_foreign_key "matchup_players", "teams"
  add_foreign_key "matchups", "seasons"
  add_foreign_key "matchups", "teams", column: "team_1_id"
  add_foreign_key "matchups", "teams", column: "team_2_id"
  add_foreign_key "matchups", "teams", column: "winner_id"
  add_foreign_key "seasons", "leagues"
  add_foreign_key "standings", "seasons"
  add_foreign_key "standings", "teams"
  add_foreign_key "teams", "managers"
  add_foreign_key "teams", "seasons"
end
