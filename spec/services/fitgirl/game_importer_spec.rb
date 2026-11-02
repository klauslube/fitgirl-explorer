require "rails_helper"

RSpec.describe Fitgirl::GameImporter do
  let(:posts) { JSON.parse(file_fixture("fitgirl/posts_recent.json").read) }
  let(:post) { posts.find { |p| p["slug"] == "deep-rock-galactic" } }
  let!(:tags) { post["tags"].map { |wp_id| create(:tag, wp_id: wp_id) } }

  it "creates a game with its tags" do
    expect(described_class.new.call(post)).to eq(:created)
    game = Game.find_by!(wp_post_id: 13349)
    expect(game.tags).to match_array(tags)
    expect(game.last_scraped_at).to be_present
  end

  it "is idempotent and detects duplicates by wp_post_id" do
    importer = described_class.new
    importer.call(post)
    expect { expect(importer.call(post)).to eq(:unchanged) }.not_to change(Game, :count)
  end

  it "updates when the post changed" do
    described_class.new.call(post)
    changed = post.merge("title" => { "rendered" => "Deep Rock Galactic: Deluxe Edition, v2.0" })
    expect(described_class.new.call(changed)).to eq(:updated)
    expect(Game.find_by!(wp_post_id: 13349).title).to include("v2.0")
  end

  it "keeps comments_count when re-importing" do
    described_class.new.call(post)
    Game.find_by!(wp_post_id: 13349).update!(comments_count: 42)
    described_class.new.call(post.merge("title" => { "rendered" => "Renamed" }))
    expect(Game.find_by!(wp_post_id: 13349).comments_count).to eq(42)
  end

  it "skips tags that were not synced" do
    Tag.delete_all
    described_class.new.call(post)
    expect(Game.find_by!(wp_post_id: 13349).tags).to be_empty
  end
end
