class SyncCommentsJob < ApplicationJob
  queue_as :default

  def perform(scope = "recent")
    sync = Fitgirl::CommentsSync.new
    scope.to_s == "all" ? sync.all : sync.recent
  end
end
