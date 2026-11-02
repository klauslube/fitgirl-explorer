require "rails_helper"

RSpec.describe Fitgirl::TolstoyClient do
  let(:http) { Fitgirl::Http.new(sleeper: ->(_) {}) }
  subject(:client) { described_class.new(http: http) }

  it "builds the md5 key from host + slug" do
    expect(described_class.key_for("deep-rock-galactic")).to eq("421b5c9987f5161173b80a649338efac")
  end

  it "maps counts back to slugs and treats missing keys as 0" do
    stub_request(:get, %r{web\.tolstoycomments\.com/api/chat/countcomment})
      .to_return(body: file_fixture("fitgirl/tolstoy_counts.json").read)

    result = client.counts(%w[deep-rock-galactic croc-2-kingdom-of-the-gobbos no-comments-here])

    expect(result).to eq("deep-rock-galactic" => 458, "croc-2-kingdom-of-the-gobbos" => 7, "no-comments-here" => 0)
  end

  it "batches 100 keys per request" do
    stub = stub_request(:get, %r{countcomment}).to_return(body: { data: { hashas: {} } }.to_json)
    client.counts((1..250).map { |i| "g-#{i}" })
    expect(stub).to have_been_requested.times(3)
  end

  it "fails loudly when the response shape changes" do
    stub_request(:get, %r{countcomment}).to_return(body: { data: { other: 1 } }.to_json)
    expect { client.counts([ "a" ]) }.to raise_error(Fitgirl::Error, /Unexpected Tolstoy/)
  end
end
