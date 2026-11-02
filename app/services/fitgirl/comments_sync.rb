module Fitgirl
  # Refreshes comments_count from Tolstoy. Recent games change fastest, so +recent+ is the cheap hourly run.
  class CommentsSync
    def initialize(client: TolstoyClient.new, logger: Rails.logger)
      @client = client
      @logger = logger
    end

    def all = run(Game.all)

    def recent(days: 30) = run(Game.where("published_at >= ?", days.days.ago))

    private

    def run(scope)
      ScrapeRun.track("comments") do |stats|
        scope.in_batches(of: TolstoyClient::BATCH_SIZE) do |batch|
          games = batch.pluck(:id, :slug)
          counts = @client.counts(games.map(&:last))
          now = Time.current
          games.each do |id, slug|
            Game.where(id: id).update_all(comments_count: counts.fetch(slug, 0), comments_synced_at: now)
            stats[:updated] += 1
          end
          @logger.info("[fitgirl] comments sync: #{stats[:updated]} games")
        end
      end
    end
  end
end
