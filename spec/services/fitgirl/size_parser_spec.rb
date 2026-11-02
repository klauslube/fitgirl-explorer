require "rails_helper"

RSpec.describe Fitgirl::SizeParser do
  GB = 1024**3

  it "parses a plain size" do
    expect(described_class.call("11.4 GB")).to eq([ (11.4 * GB).round ] * 2)
  end

  it "accepts decimal commas and MB" do
    expect(described_class.call("3,3 GB")).to eq([ (3.3 * GB).round ] * 2)
    expect(described_class.call("500 MB")).to eq([ 500 * 1024**2 ] * 2)
  end

  it "parses a range with the unit at the end" do
    expect(described_class.call("2.1/2.3 GB")).to eq([ (2.1 * GB).round, (2.3 * GB).round ])
  end

  it "ignores the 'from' prefix and trailing notes" do
    expect(described_class.call("from 2.6 GB [Selective Download]")).to eq([ (2.6 * GB).round ] * 2)
  end

  it "returns nil when there is nothing numeric" do
    expect(described_class.call("unknown")).to be_nil
    expect(described_class.call(nil)).to be_nil
  end
end
