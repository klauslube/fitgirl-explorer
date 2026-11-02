class DashboardController < ApplicationController
  def show
    @games_count = Game.count
    @tags_count = Tag.where("games_count > 0").count
    @comments_total = Game.sum(:comments_count)
    @last_sync = ScrapeRun.succeeded.maximum(:finished_at)
    @most_commented = Game.includes(:tags).order(comments_count: :desc).limit(8)
    @latest = Game.includes(:tags).order(published_at: :desc).limit(8)
    @top_tags = Tag.where("games_count > 0").popular.limit(14)
  end
end
