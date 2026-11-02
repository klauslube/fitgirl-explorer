class GamesController < ApplicationController
  def index
    @search = GameSearch.new(params)
    @pagy, @games = pagy(@search.call.includes(:tags), page: [ params[:page].to_i, 1 ].max)
    @selected_tags = Tag.where(id: @search.tag_ids).order(:name)
    @popular_tags = Tag.popular.where("games_count > 0").where.not(id: @search.tag_ids).limit(20)
  end

  def show
    @game = Game.includes(:tags).find_by!(slug: params[:slug])
    @related = Game.joins(:game_tags).where(game_tags: { tag_id: @game.tag_ids })
                   .where.not(id: @game.id).group("games.id").order(Arel.sql("COUNT(*) DESC, games.comments_count DESC"))
                   .limit(6).includes(:tags)
  end
end
