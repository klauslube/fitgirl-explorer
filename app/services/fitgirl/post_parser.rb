module Fitgirl
  # Turns one WordPress REST post into Game attributes. Only metadata is read: the download-link
  # blocks of the post are never inspected or stored. Missing fields come back as nil.
  class PostParser
    Result = Struct.new(:attributes, :tag_wp_ids, keyword_init: true)

    def self.call(post) = new(post).call

    def initialize(post)
      @post = post
    end

    def call
      title = decode(@post.dig("title", "rendered"))
      fields = info_fields
      repack = SizeParser.call(fields["repack size"])
      original = SizeParser.call(fields["original size"])

      Result.new(
        tag_wp_ids: Array(@post["tags"]).map(&:to_i),
        attributes: {
          wp_post_id: @post.fetch("id"),
          slug: @post.fetch("slug"),
          title: title,
          search_title: TitleNormalizer.call(title),
          source_url: @post.fetch("link"),
          published_at: parse_time(@post.fetch("date_gmt")),
          modified_at: parse_time(@post["modified_gmt"]),
          original_size_bytes: original&.last,
          repack_size_min_bytes: repack&.first,
          repack_size_max_bytes: repack&.last,
          cover_url: cover_url,
          companies: split_list(fields["companies"] || fields["company"]),
          languages: fields["languages"].presence,
          repack_number: repack_number
        }
      )
    end

    private

    def doc
      @doc ||= Nokogiri::HTML.fragment(@post.dig("content", "rendered").to_s)
    end

    # The info paragraph is the first element holding "Original Size:". Lines are separated by <br>.
    def info_block
      @info_block ||= doc.css("p").find { |p| p.text.include?("Original Size") }
    end

    def info_fields
      return {} unless info_block
      block = info_block.dup
      block.css("br").each { |br| br.replace("\n") }
      block.text.split("\n").each_with_object({}) do |line, fields|
        key, value = line.split(":", 2)
        next unless value
        fields[key.strip.downcase] = value.squish
      end
    end

    def cover_url
      src = info_block&.at_css("img")&.[]("src") || doc.at_css("img")&.[]("src")
      src if src&.match?(%r{\Ahttps?://})
    end

    def repack_number
      doc.at_css("h3 span")&.text&.[](/#(\d+)/, 1)&.to_i
    end

    def split_list(text)
      text.to_s.split(",").map(&:squish).reject(&:blank?)
    end

    def parse_time(value)
      return if value.blank?
      Time.find_zone!("UTC").parse(value)
    end

    def decode(html)
      Nokogiri::HTML.fragment(html.to_s).text.squish
    end
  end
end
