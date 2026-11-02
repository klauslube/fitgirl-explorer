class Game < ApplicationRecord
  SORTS = {
    "comments_desc" => "games.comments_count DESC, games.published_at DESC",
    "comments_asc"  => "games.comments_count ASC, games.published_at DESC",
    "newest"        => "games.published_at DESC",
    "oldest"        => "games.published_at ASC",
    "name"          => "games.search_title ASC",
    "size_desc"     => "games.repack_size_min_bytes DESC NULLS LAST",
    "size_asc"      => "games.repack_size_min_bytes ASC NULLS LAST"
  }.freeze
  DEFAULT_SORT = "comments_desc".freeze

  has_many :game_tags, dependent: :delete_all
  has_many :tags, through: :game_tags

  validates :wp_post_id, :slug, :title, :search_title, :source_url, :published_at, presence: true
  validates :wp_post_id, :slug, uniqueness: true
  validates :comments_count, numericality: { greater_than_or_equal_to: 0 }

  scope :search, ->(query) {
    next all if query.blank?
    where("games.search_title ILIKE ?", "%#{sanitize_sql_like(query.to_s.strip.downcase)}%")
  }
  # AND semantics: the game must carry every selected tag.
  scope :with_tags, ->(tag_ids) {
    ids = Array(tag_ids).map(&:to_i).reject(&:zero?).uniq
    next all if ids.empty?
    where(id: GameTag.where(tag_id: ids).group(:game_id).having("COUNT(*) = ?", ids.size).select(:game_id))
  }
  scope :min_comments, ->(n) { n.to_i.positive? ? where("games.comments_count >= ?", n.to_i) : all }
  scope :published_between, ->(from, to) {
    rel = all
    rel = rel.where("games.published_at >= ?", from.beginning_of_day) if from
    rel = rel.where("games.published_at <= ?", to.end_of_day) if to
    rel
  }
  scope :repack_size_between, ->(min_bytes, max_bytes) {
    rel = all
    rel = rel.where("games.repack_size_min_bytes >= ?", min_bytes) if min_bytes
    rel = rel.where("games.repack_size_min_bytes <= ?", max_bytes) if max_bytes
    rel
  }
  scope :sorted_by, ->(key) { order(Arel.sql(SORTS.fetch(key.to_s, SORTS[DEFAULT_SORT]))) }

  def repack_size_range?
    repack_size_min_bytes && repack_size_max_bytes && repack_size_max_bytes > repack_size_min_bytes
  end

  def to_param = slug
end
