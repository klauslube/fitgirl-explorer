require "rails_helper"

RSpec.describe Tag do
  it { is_expected.to validate_presence_of(:name) }

  it ".refresh_counts! recomputes games_count" do
    tag = create(:tag)
    create(:game).tags << tag
    create(:game).tags << tag
    expect { described_class.refresh_counts! }.to change { tag.reload.games_count }.from(0).to(2)
  end
end
