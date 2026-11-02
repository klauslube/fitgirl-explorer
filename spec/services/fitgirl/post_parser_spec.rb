require "rails_helper"

RSpec.describe Fitgirl::PostParser do
  def posts(name) = JSON.parse(file_fixture("fitgirl/#{name}.json").read)
  def parse(name, slug) = described_class.call(posts(name).find { |p| p["slug"] == slug })

  let(:gb) { 1024**3 }

  it "extracts every field from a recent post with a range size" do
    r = parse("posts_recent", "deep-rock-galactic")
    a = r.attributes
    expect(a).to include(
      wp_post_id: 13349, slug: "deep-rock-galactic",
      title: "Deep Rock Galactic: Deluxe Edition, v1.40.158958.0 + 13 DLCs/Bonuses",
      search_title: "deep rock galactic: deluxe edition",
      source_url: "https://fitgirl-repacks.site/deep-rock-galactic/",
      original_size_bytes: (5.3 * gb).round,
      repack_size_min_bytes: (2.6 * gb).round,
      repack_size_max_bytes: (2.8 * gb).round,
      languages: "RUS/ENG/MULTI15",
      companies: [ "Ghost Ship Games", "Coffee Stain Studios" ],
      repack_number: 1419
    )
    expect(a[:published_at]).to be_a(Time)
    expect(a[:cover_url]).to start_with("http")
    expect(r.tag_wp_ids).to eq(posts("posts_recent").find { |p| p["slug"] == "deep-rock-galactic" }["tags"])
    expect(r.tag_wp_ids).not_to be_empty
  end

  it "reads the 'from X GB' repack size" do
    a = parse("posts_recent", "croc-2-kingdom-of-the-gobbos").attributes
    expect(a[:repack_size_min_bytes]).to eq((2.6 * gb).round)
    expect(a[:repack_size_max_bytes]).to eq(a[:repack_size_min_bytes])
    expect(a[:original_size_bytes]).to eq((11.4 * gb).round)
  end

  it "handles old posts: decimal comma, 'Company:', no genres" do
    r = parse("posts_old", "kholat")
    expect(r.attributes).to include(companies: [ "IMGN.PRO" ], original_size_bytes: (3.3 * gb).round)
    expect(r.tag_wp_ids).to eq([])
  end

  it "returns nils instead of failing when the info block is missing" do
    post = { "id" => 1, "slug" => "x", "link" => "https://fitgirl-repacks.site/x/", "title" => { "rendered" => "X" },
             "date_gmt" => "2026-01-01T00:00:00", "content" => { "rendered" => "<p>nothing here</p>" }, "tags" => [] }
    a = described_class.call(post).attributes
    expect(a).to include(original_size_bytes: nil, repack_size_min_bytes: nil, cover_url: nil, companies: [], languages: nil)
  end

  it "never exposes download links" do
    all = posts("posts_recent").map { |p| described_class.call(p).attributes.values.join(" ") }.join(" ")
    expect(all).not_to match(/magnet:|\.torrent|datanodes|fuckingfast/i)
  end
end
