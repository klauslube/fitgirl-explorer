class Tag < ApplicationRecord
  has_many :game_tags, dependent: :delete_all
  has_many :games, through: :game_tags

  validates :name, :slug, presence: true
  validates :slug, uniqueness: true

  scope :popular, -> { order(games_count: :desc, name: :asc) }

  def self.refresh_counts!
    connection.execute(<<~SQL)
      UPDATE tags SET games_count = (SELECT COUNT(*) FROM game_tags WHERE game_tags.tag_id = tags.id)
    SQL
  end
end
