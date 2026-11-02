require "rails_helper"

RSpec.describe Fitgirl::TitleNormalizer do
  it "drops version and DLC suffixes" do
    expect(described_class.call("Deep Rock Galactic: Deluxe Edition, v1.40.158958.0 + 13 DLCs/Bonuses"))
      .to eq("deep rock galactic: deluxe edition")
    expect(described_class.call("Onimusha: Way of the Sword – Premium Deluxe Edition, v01.000.001 + 23 DLCs"))
      .to eq("onimusha: way of the sword – premium deluxe edition".then { I18n.transliterate(_1) })
  end

  it "drops a trailing '+ N DLCs' without a version" do
    expect(described_class.call("ANOMALITH: Digital Deluxe Edition + 5 DLCs/Bonuses")).to eq("anomalith: digital deluxe edition")
  end

  it "leaves plain titles alone" do
    expect(described_class.call("Croc 2: Kingdom of the Gobbos")).to eq("croc 2: kingdom of the gobbos")
  end
end
