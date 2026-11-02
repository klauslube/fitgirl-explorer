FactoryBot.define do
  factory :tag do
    sequence(:name) { |n| "Tag #{n}" }
    sequence(:slug) { |n| "tag-#{n}" }
    sequence(:wp_id) { |n| 1000 + n }
  end

  factory :game do
    sequence(:wp_post_id) { |n| 5000 + n }
    sequence(:slug) { |n| "game-#{n}" }
    sequence(:title) { |n| "Game #{n}" }
    search_title { title.downcase }
    source_url { "https://fitgirl-repacks.site/#{slug}/" }
    published_at { Time.utc(2026, 1, 1) }
    comments_count { 0 }
  end
end
