module Fitgirl
  # Orchestrates the initial import (+full+) and the incremental update.
  class CatalogSync
    def initialize(client: WpClient.new, logger: Rails.logger)
      @client = client
      @logger = logger
    end

    def full = run("full", modified_after: nil)

    def incremental
      since = %w[full incremental].filter_map { |k| ScrapeRun.last_success_started_at(k) }.max
      raise Error, "No previous successful sync: run the full import first" unless since
      run("incremental", modified_after: since - 5.minutes)
    end

    private

    def run(kind, modified_after:)
      ScrapeRun.track(kind) do |stats|
        sync_tags(stats)
        importer = GameImporter.new
        category_id = @client.category_id
        @client.each_posts_page(category_id: category_id, modified_after: modified_after) do |posts, page, total|
          @logger.info("[fitgirl] #{kind} sync: page #{page}/#{total} (#{posts.size} posts)")
          posts.each { |post| import_post(importer, post, stats) }
        end
        Tag.refresh_counts!
      end
    end

    def sync_tags(stats)
      @client.each_tag do |t|
        tag = Tag.find_or_initialize_by(wp_id: t["id"])
        tag.update!(name: Nokogiri::HTML.fragment(t["name"]).text, slug: t["slug"])
        stats[:tags] += 1
      end
    end

    def import_post(importer, post, stats)
      stats[importer.call(post)] += 1
    rescue ActiveRecord::ActiveRecordError, KeyError, ArgumentError => e
      stats[:failed] += 1
      @logger.error("[fitgirl] failed to import post #{post['id']} (#{post['slug']}): #{e.class}: #{e.message}")
    end
  end
end
