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

ActiveRecord::Schema[8.1].define(version: 2026_11_02_100300) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  create_table "game_tags", force: :cascade do |t|
    t.bigint "game_id", null: false
    t.bigint "tag_id", null: false
    t.index ["game_id", "tag_id"], name: "index_game_tags_on_game_id_and_tag_id", unique: true
    t.index ["tag_id", "game_id"], name: "index_game_tags_on_tag_id_and_game_id"
  end

  create_table "games", force: :cascade do |t|
    t.bigint "wp_post_id", null: false
    t.string "slug", null: false
    t.string "title", null: false
    t.string "search_title", null: false
    t.string "source_url", null: false
    t.datetime "published_at", null: false
    t.datetime "modified_at"
    t.integer "comments_count", default: 0, null: false
    t.datetime "comments_synced_at"
    t.bigint "original_size_bytes"
    t.bigint "repack_size_min_bytes"
    t.bigint "repack_size_max_bytes"
    t.string "cover_url"
    t.text "description"
    t.string "companies", default: [], null: false, array: true
    t.string "languages"
    t.integer "repack_number"
    t.datetime "last_scraped_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["comments_count"], name: "index_games_on_comments_count"
    t.index ["comments_synced_at"], name: "index_games_on_comments_synced_at"
    t.index ["companies"], name: "index_games_on_companies", using: :gin
    t.index ["published_at"], name: "index_games_on_published_at"
    t.index ["repack_size_min_bytes"], name: "index_games_on_repack_size_min_bytes"
    t.index ["search_title"], name: "index_games_on_search_title", opclass: :gin_trgm_ops, using: :gin
    t.index ["slug"], name: "index_games_on_slug", unique: true
    t.index ["wp_post_id"], name: "index_games_on_wp_post_id", unique: true
    t.check_constraint "comments_count >= 0", name: "games_comments_count_nonneg"
    t.check_constraint "repack_size_max_bytes IS NULL OR repack_size_min_bytes IS NULL OR repack_size_max_bytes >= repack_size_min_bytes", name: "games_repack_size_range"
  end

  create_table "scrape_runs", force: :cascade do |t|
    t.string "kind", null: false
    t.string "status", default: "running", null: false
    t.datetime "started_at", null: false
    t.datetime "finished_at"
    t.jsonb "stats", default: {}, null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["kind", "status", "finished_at"], name: "index_scrape_runs_on_kind_and_status_and_finished_at"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.bigint "wp_id"
    t.integer "games_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["games_count"], name: "index_tags_on_games_count"
    t.index ["slug"], name: "index_tags_on_slug", unique: true
    t.index ["wp_id"], name: "index_tags_on_wp_id", unique: true
  end

  add_foreign_key "game_tags", "games", on_delete: :cascade
  add_foreign_key "game_tags", "tags", on_delete: :cascade
end
