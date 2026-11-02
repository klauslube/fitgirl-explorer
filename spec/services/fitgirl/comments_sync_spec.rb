require "rails_helper"

RSpec.describe Fitgirl::CommentsSync do
  let(:client) { instance_double(Fitgirl::TolstoyClient) }

  it "updates counts, defaulting to 0 and stamping the sync time" do
    hot = create(:game, slug: "hot", comments_count: 1)
    quiet = create(:game, slug: "quiet", comments_count: 5)
    allow(client).to receive(:counts).with(match_array(%w[hot quiet])).and_return("hot" => 458, "quiet" => 0)

    described_class.new(client: client, logger: Logger.new(nil)).all

    expect(hot.reload.comments_count).to eq(458)
    expect(quiet.reload.comments_count).to eq(0)
    expect(hot.comments_synced_at).to be_present
    expect(ScrapeRun.last.stats).to include("updated" => 2)
  end

  it "recent only touches recently published games" do
    old = create(:game, slug: "old", published_at: 1.year.ago)
    fresh = create(:game, slug: "fresh", published_at: 2.days.ago)
    allow(client).to receive(:counts).with([ "fresh" ]).and_return("fresh" => 3)

    described_class.new(client: client, logger: Logger.new(nil)).recent

    expect(fresh.reload.comments_count).to eq(3)
    expect(old.reload.comments_synced_at).to be_nil
  end
end
