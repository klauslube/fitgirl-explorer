require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  it "shows an empty state before the first import" do
    get root_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("The catalog is empty")
  end

  it "lists totals, most commented, latest and genres" do
    tag = create(:tag, name: "Horror")
    hot = create(:game, title: "Hot Game", comments_count: 300, published_at: 2.years.ago)
    fresh = create(:game, title: "Fresh Game", comments_count: 0, published_at: 1.day.ago)
    hot.tags << tag
    Tag.refresh_counts!

    get root_path

    expect(response.body).to include("Hot Game", "Fresh Game", "Horror", "Games indexed")
    expect(response.body.index("Hot Game")).to be < response.body.index("Fresh Game")
  end
end
