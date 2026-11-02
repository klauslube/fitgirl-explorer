# Builds the catalog relation from GET params. Invalid values are ignored, never raised.
class GameSearch
  GB = 1024**3

  attr_reader :params

  def initialize(params = {})
    @params = (params.respond_to?(:to_unsafe_h) ? params.to_unsafe_h : params.to_h).with_indifferent_access
  end

  def call
    Game.search(query)
        .with_tags(tag_ids)
        .min_comments(min_comments)
        .published_between(from, to)
        .repack_size_between(min_size_bytes, max_size_bytes)
        .sorted_by(sort)
  end

  def query = params[:q].to_s.strip.presence
  def tag_ids = Array(params[:tag_ids]).map(&:to_i).reject(&:zero?).uniq
  def min_comments = params[:min_comments].to_i.clamp(0, 1_000_000)
  def from = parse_date(params[:from])
  def to = parse_date(params[:to])
  def min_size_bytes = gb_to_bytes(params[:min_size])
  def max_size_bytes = gb_to_bytes(params[:max_size])
  def sort = Game::SORTS.key?(params[:sort].to_s) ? params[:sort].to_s : Game::DEFAULT_SORT

  def filtered?
    query || tag_ids.any? || min_comments.positive? || from || to || min_size_bytes || max_size_bytes
  end

  private

  def parse_date(value)
    Date.iso8601(value.to_s)
  rescue ArgumentError
    nil
  end

  def gb_to_bytes(value)
    number = Float(value.to_s.tr(",", "."), exception: false)
    (number * GB).round if number && number >= 0
  end
end
