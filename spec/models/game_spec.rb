require "rails_helper"

RSpec.describe Game do
  subject { build(:game) }

  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:wp_post_id) }
  it { is_expected.to validate_uniqueness_of(:slug) }
  it { is_expected.to validate_numericality_of(:comments_count).is_greater_than_or_equal_to(0) }

  it "enforces uniqueness of wp_post_id in the database" do
    create(:game, wp_post_id: 1)
    expect { build(:game, wp_post_id: 1).save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "rejects an inverted repack size range at the database level" do
    g = build(:game, repack_size_min_bytes: 10, repack_size_max_bytes: 5)
    expect { g.save!(validate: false) }.to raise_error(ActiveRecord::StatementInvalid, /games_repack_size_range/)
  end

  describe "scopes" do
    let!(:old_quiet) { create(:game, title: "Alpha Quest", search_title: "alpha quest", comments_count: 1, published_at: Time.utc(2020, 1, 5), repack_size_min_bytes: 2.gigabytes) }
    let!(:new_hot)   { create(:game, title: "Beta Wars",   search_title: "beta wars",   comments_count: 90, published_at: Time.utc(2026, 5, 5), repack_size_min_bytes: 10.gigabytes) }
    let!(:no_size)   { create(:game, title: "Gamma",       search_title: "gamma",       comments_count: 10, published_at: Time.utc(2024, 1, 1)) }

    it ".search matches case-insensitively and escapes wildcards" do
      expect(Game.search("BETA")).to contain_exactly(new_hot)
      expect(Game.search("%")).to be_empty
      expect(Game.search("")).to match_array(Game.all)
    end

    it ".min_comments" do
      expect(Game.min_comments(10)).to contain_exactly(new_hot, no_size)
    end

    it ".published_between is inclusive on both days" do
      expect(Game.published_between(Date.new(2024, 1, 1), Date.new(2026, 5, 5))).to contain_exactly(new_hot, no_size)
      expect(Game.published_between(nil, Date.new(2020, 1, 5))).to contain_exactly(old_quiet)
    end

    it ".repack_size_between ignores games without size when bounds are given" do
      expect(Game.repack_size_between(1.gigabyte, 5.gigabytes)).to contain_exactly(old_quiet)
    end

    it ".sorted_by orders and puts unknown sizes last" do
      expect(Game.sorted_by("comments_desc").to_a).to eq([ new_hot, no_size, old_quiet ])
      expect(Game.sorted_by("comments_asc").first).to eq(old_quiet)
      expect(Game.sorted_by("oldest").first).to eq(old_quiet)
      expect(Game.sorted_by("name").first).to eq(old_quiet)
      expect(Game.sorted_by("size_desc").to_a).to eq([ new_hot, old_quiet, no_size ])
      expect(Game.sorted_by("size_asc").to_a).to eq([ old_quiet, new_hot, no_size ])
    end

    it ".sorted_by falls back to the default for unknown keys (no SQL injection)" do
      expect(Game.sorted_by("id; DROP TABLE games").first).to eq(new_hot)
    end

    it ".with_tags requires ALL selected tags" do
      a, b = create(:tag), create(:tag)
      old_quiet.tags << [ a, b ]
      new_hot.tags << a
      expect(Game.with_tags([ a.id ])).to contain_exactly(old_quiet, new_hot)
      expect(Game.with_tags([ a.id, b.id ])).to contain_exactly(old_quiet)
      expect(Game.with_tags([])).to match_array(Game.all)
    end
  end
end
