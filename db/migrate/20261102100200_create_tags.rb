class CreateTags < ActiveRecord::Migration[8.1]
  def change
    create_table :tags do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.bigint :wp_id
      t.integer :games_count, null: false, default: 0
      t.timestamps
    end
    add_index :tags, :slug, unique: true
    add_index :tags, :wp_id, unique: true
    add_index :tags, :games_count

    create_table :game_tags do |t|
      t.references :game, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.references :tag, null: false, foreign_key: { on_delete: :cascade }, index: false
    end
    add_index :game_tags, %i[game_id tag_id], unique: true
    add_index :game_tags, %i[tag_id game_id]
  end
end
