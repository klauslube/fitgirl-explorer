require "rails_helper"

RSpec.describe "Games", type: :request do
  describe "GET /games" do
    let!(:hot)   { create(:game, title: "Hot Shooter", search_title: "hot shooter", comments_count: 500, published_at: Time.utc(2026, 3, 1), repack_size_min_bytes: 5.gigabytes) }
    let!(:quiet) { create(:game, title: "Quiet Puzzle", search_title: "quiet puzzle", comments_count: 2, published_at: Time.utc(2020, 3, 1), repack_size_min_bytes: 1.gigabyte) }
    let!(:shooter_tag) { create(:tag, name: "Shooter") }
    before { hot.tags << shooter_tag; Tag.refresh_counts! }

    it "renders the grid sorted by most commented by default" do
      get games_path
      expect(response).to have_http_status(:ok)
      expect(response.body.index("Hot Shooter")).to be < response.body.index("Quiet Puzzle")
    end

    it "filters by name, tag, comments, dates and size through GET params" do
      get games_path, params: { q: "shooter", tag_ids: [ shooter_tag.id ], min_comments: 100, from: "2026-01-01", min_size: 2 }
      expect(response.body).to include("Hot Shooter")
      expect(response.body).not_to include("Quiet Puzzle")
    end

    it "respects the sort param" do
      get games_path, params: { sort: "oldest" }
      expect(response.body.index("Quiet Puzzle")).to be < response.body.index("Hot Shooter")
    end

    it "shows a designed empty state when nothing matches" do
      get games_path, params: { q: "zzzz-nothing" }
      expect(response.body).to include("No games match these filters")
    end

    it "survives garbage params" do
      get games_path, params: { min_comments: "abc", from: "xx", sort: "'; drop", page: "-4", tag_ids: [ "a" ] }
      expect(response).to have_http_status(:ok)
    end

    it "paginates at the backend" do
      create_list(:game, 30)
      get games_path
      expect(response.body.scan("game-card").size).to eq(Pagy::DEFAULT[:limit])
      expect(response.body).to include("Next")
    end

    it "does not run an N+1 on tags" do
      create_list(:game, 5).each { |g| g.tags << create(:tag) }
      queries = []
      sub = ActiveSupport::Notifications.subscribe("sql.active_record") { |*, p| queries << p[:sql] if p[:sql] =~ /FROM "tags"/ }
      get games_path
      ActiveSupport::Notifications.unsubscribe(sub)
      expect(queries.size).to be <= 4
    end
  end

  describe "GET /games/:slug" do
    it "shows the details and the link to the original post" do
      game = create(:game, title: "Detail Game", slug: "detail-game", comments_count: 12, repack_size_min_bytes: 2.gigabytes,
                           repack_size_max_bytes: 3.gigabytes, original_size_bytes: 6.gigabytes, companies: [ "Studio X" ])
      get game_path(game)
      expect(response.body).to include("Detail Game", "2.0 GB – 3.0 GB", "6.0 GB", "Studio X", game.source_url)
    end

    it "renders a friendly 404" do
      get game_path("does-not-exist")
      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("couldn&#39;t find that game")
    end
  end

  describe "GET /tags" do
    it "narrows the tag list and keeps selected tags" do
      a = create(:tag, name: "Action"); b = create(:tag, name: "Horror"); create(:game).tags << [ a, b ]
      Tag.refresh_counts!
      get tags_path, params: { tag_q: "hor", tag_ids: [ a.id ] }
      expect(response.body).to include("Horror", "Action")
    end
  end
end
