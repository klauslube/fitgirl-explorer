require "rails_helper"

RSpec.describe Fitgirl::CatalogSync do
  let(:posts) { JSON.parse(file_fixture("fitgirl/posts_recent.json").read) }
  let(:tags_json) { JSON.parse(file_fixture("fitgirl/tags_page1.json").read) }
  let(:client) { instance_double(Fitgirl::WpClient, category_id: 5) }
  let(:logger) { Logger.new(nil) }

  before do
    allow(client).to receive(:each_tag) { |&b| tags_json.each(&b) }
    allow(client).to receive(:each_posts_page) { |**_, &b| b.call(posts, 1, 1) }
  end

  it "imports the catalog and records a successful run" do
    run = described_class.new(client: client, logger: logger).full

    expect(Game.count).to eq(posts.size)
    expect(Tag.count).to eq(tags_json.size)
    expect(run.status).to eq("succeeded")
    expect(run.stats).to include("created" => posts.size)
    expect(Tag.where("games_count > 0")).to exist
  end

  it "counts a broken post as failed and keeps going" do
    broken = posts.first.merge("date_gmt" => "garbage")
    allow(client).to receive(:each_posts_page) { |**_, &b| b.call([ broken, *posts.drop(1) ], 1, 1) }

    run = described_class.new(client: client, logger: logger).full

    expect(run.stats).to include("failed" => 1, "created" => posts.size - 1)
  end

  it "marks the run as failed when the source blocks us" do
    allow(client).to receive(:each_posts_page).and_raise(Fitgirl::BlockedError, "HTTP 403")
    expect { described_class.new(client: client, logger: logger).full }.to raise_error(Fitgirl::BlockedError)
    expect(ScrapeRun.last).to have_attributes(status: "failed", error: /BlockedError/)
  end

  it "refuses an incremental run before any full import" do
    expect { described_class.new(client: client, logger: logger).incremental }.to raise_error(Fitgirl::Error, /full import/)
  end

  it "passes modified_after (with overlap) on incremental runs" do
    described_class.new(client: client, logger: logger).full
    described_class.new(client: client, logger: logger).incremental
    expect(client).to have_received(:each_posts_page).with(hash_including(modified_after: kind_of(Time))).once
  end
end
