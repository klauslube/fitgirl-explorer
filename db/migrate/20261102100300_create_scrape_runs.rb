class CreateScrapeRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :scrape_runs do |t|
      t.string :kind, null: false
      t.string :status, null: false, default: "running"
      t.datetime :started_at, null: false
      t.datetime :finished_at
      t.jsonb :stats, null: false, default: {}
      t.text :error
      t.timestamps
    end
    add_index :scrape_runs, %i[kind status finished_at]
  end
end
