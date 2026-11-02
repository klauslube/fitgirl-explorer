class SyncCatalogJob < ApplicationJob
  queue_as :default

  def perform(mode = "incremental")
    sync = Fitgirl::CatalogSync.new
    mode.to_s == "full" ? sync.full : sync.incremental
    SyncCommentsJob.perform_later(mode.to_s == "full" ? "all" : "recent")
  end
end
