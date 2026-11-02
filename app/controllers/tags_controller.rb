class TagsController < ApplicationController
  # Renders the tag checkbox list for the sidebar (Turbo Frame), narrowed by ?q=
  def index
    @selected_ids = Array(params[:tag_ids]).map(&:to_i)
    scope = Tag.where("games_count > 0")
    scope = scope.where("name ILIKE ?", "%#{Tag.sanitize_sql_like(params[:tag_q].to_s.strip)}%") if params[:tag_q].present?
    @tags = scope.where.not(id: @selected_ids).popular.limit(40)
    @selected = Tag.where(id: @selected_ids).order(:name)
  end
end
