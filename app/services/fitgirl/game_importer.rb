module Fitgirl
  # Idempotent upsert of one REST post. Duplicates are identified by wp_post_id.
  class GameImporter
    def initialize(tag_ids_by_wp_id: nil)
      @tag_ids_by_wp_id = tag_ids_by_wp_id
    end

    # Returns :created, :updated or :unchanged.
    def call(post)
      parsed = PostParser.call(post)
      game = Game.find_or_initialize_by(wp_post_id: parsed.attributes[:wp_post_id])
      outcome = game.new_record? ? :created : :updated

      Game.transaction do
        game.assign_attributes(parsed.attributes.merge(last_scraped_at: Time.current))
        outcome = :unchanged if outcome == :updated && !game.changed_attributes.except("last_scraped_at").any?
        game.save!
        game.tag_ids = resolve_tag_ids(parsed.tag_wp_ids)
      end
      outcome
    end

    private

    def tag_ids_by_wp_id
      @tag_ids_by_wp_id ||= Tag.where.not(wp_id: nil).pluck(:wp_id, :id).to_h
    end

    def resolve_tag_ids(wp_ids)
      wp_ids.filter_map { |wp_id| tag_ids_by_wp_id[wp_id] }
    end
  end
end
