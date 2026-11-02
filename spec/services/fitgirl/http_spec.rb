require "rails_helper"

RSpec.describe Fitgirl::Http do
  let(:sleeps) { [] }
  let(:http) { described_class.new(sleeper: ->(s) { sleeps << s }) }
  let(:url) { "https://fitgirl-repacks.site/wp-json/wp/v2/tags" }

  around do |ex|
    old = described_class.delay
    described_class.delay = 0
    ex.run
    described_class.delay = old
  end

  it "retries transient failures and honours Retry-After" do
    stub_request(:get, url).to_return({ status: 429, headers: { "Retry-After" => "7" } }, { status: 200, body: "[]" })
    expect(http.get_json(url)).to eq([])
    expect(sleeps).to include(7.0)
  end

  it "gives up after max retries" do
    stub_request(:get, url).to_return(status: 503)
    expect { http.get(url) }.to raise_error(Fitgirl::RequestError)
    expect(a_request(:get, url)).to have_been_made.times(described_class.max_retries + 1)
  end

  it "does not retry a 403 (no bypass)" do
    stub_request(:get, url).to_return(status: 403)
    expect { http.get(url) }.to raise_error(Fitgirl::BlockedError)
    expect(a_request(:get, url)).to have_been_made.once
  end

  it "treats a non-JSON body as a probable challenge page" do
    stub_request(:get, url).to_return(status: 200, body: "<html>checking your browser</html>")
    expect { http.get_json(url) }.to raise_error(Fitgirl::BlockedError)
  end
end
