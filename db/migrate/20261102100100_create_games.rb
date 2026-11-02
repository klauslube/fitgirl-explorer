class CreateGames < ActiveRecord::Migration[8.1]
  def change
    create_table :games do |t|
      t.bigint :wp_post_id, null: false
      t.string :slug, null: false
      t.string :title, null: false
      t.string :search_title, null: false
      t.string :source_url, null: false
      t.datetime :published_at, null: false
      t.datetime :modified_at
      t.integer :comments_count, null: false, default: 0
      t.datetime :comments_synced_at
      t.bigint :original_size_bytes
      t.bigint :repack_size_min_bytes
      t.bigint :repack_size_max_bytes
      t.string :cover_url
      t.text :description
      t.string :companies, array: true, default: [], null: false
      t.string :languages
      t.integer :repack_number
      t.datetime :last_scraped_at
      t.timestamps
    end

    add_index :games, :wp_post_id, unique: true
    add_index :games, :slug, unique: true
    add_index :games, :comments_count
    add_index :games, :published_at
    add_index :games, :repack_size_min_bytes
    add_index :games, :comments_synced_at
    add_index :games, :search_title, using: :gin, opclass: :gin_trgm_ops
    add_index :games, :companies, using: :gin

    add_check_constraint :games, "comments_count >= 0", name: "games_comments_count_nonneg"
    add_check_constraint :games,
      "repack_size_max_bytes IS NULL OR repack_size_min_bytes IS NULL OR repack_size_max_bytes >= repack_size_min_bytes",
      name: "games_repack_size_range"
  end
end
