require "rails_helper"

RSpec.describe GameSearch do
  let(:gb) { 1024**3 }

  it "combines filters" do
    tag = create(:tag)
    match = create(:game, search_title: "dark quest", comments_count: 50, repack_size_min_bytes: 3 * gb, published_at: Time.utc(2025, 6, 1))
    match.tags << tag
    create(:game, search_title: "dark quest 2", comments_count: 5, repack_size_min_bytes: 3 * gb, published_at: Time.utc(2025, 6, 1)).tags << tag
    create(:game, search_title: "dark quest 3", comments_count: 50, repack_size_min_bytes: 30 * gb, published_at: Time.utc(2025, 6, 1)).tags << tag

    result = described_class.new(q: "dark", tag_ids: [ tag.id.to_s ], min_comments: "10", from: "2025-01-01", to: "2025-12-31", min_size: "1", max_size: "5").call

    expect(result).to contain_exactly(match)
  end

  it "ignores garbage params instead of raising" do
    create(:game)
    search = described_class.new(min_comments: "abc", from: "not-a-date", min_size: "x", sort: "bogus", tag_ids: [ "0", "" ])
    expect(search.call.count).to eq(1)
    expect(search).not_to be_filtered
    expect(search.sort).to eq("comments_desc")
  end

  it "accepts ActionController::Parameters" do
    params = ActionController::Parameters.new(q: "x", min_comments: "3")
    expect(described_class.new(params).min_comments).to eq(3)
  end
end
