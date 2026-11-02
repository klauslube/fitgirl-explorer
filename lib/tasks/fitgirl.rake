namespace :fitgirl do
  desc "Initial import of the Lossless Repack catalog, then comment counts (slow: ~4s between requests)"
  task import: :environment do
    Rails.logger = ActiveSupport::Logger.new($stdout)
    Fitgirl::CatalogSync.new.full
    Fitgirl::CommentsSync.new.all
  end

  desc "Incremental update (posts modified since the last run) + recent comment counts"
  task sync: :environment do
    Rails.logger = ActiveSupport::Logger.new($stdout)
    Fitgirl::CatalogSync.new.incremental
    Fitgirl::CommentsSync.new.recent
  end

  desc "Refresh comment counts for every game"
  task comments: :environment do
    Rails.logger = ActiveSupport::Logger.new($stdout)
    Fitgirl::CommentsSync.new.all
  end
end
