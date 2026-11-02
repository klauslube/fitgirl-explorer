module Fitgirl
  # Reads the public WordPress REST API of the source site.
  class WpClient
    BASE = "https://fitgirl-repacks.site/wp-json/wp/v2".freeze
    POST_FIELDS = %w[id slug date_gmt modified_gmt link title content tags categories].freeze
    CATEGORY_SLUG = "lossless-repack".freeze

    def initialize(http: Http.new)
      @http = http
    end

    def category_id(slug = CATEGORY_SLUG)
      list = @http.get_json("#{BASE}/categories?slug=#{slug}&_fields=id,slug")
      list.first&.fetch("id") or raise Error, "Category #{slug.inspect} not found"
    end

    # Yields each page (Array of post hashes) in chronological order of modification when
    # +modified_after+ is given, newest first otherwise.
    def each_posts_page(category_id:, modified_after: nil, per_page: 100)
      page = 1
      total_pages = 1
      while page <= total_pages
        response = @http.get(posts_url(category_id, modified_after, per_page, page))
        total_pages = response["X-WP-TotalPages"].to_i
        total_pages = 1 if total_pages.zero?
        yield JSON.parse(response.body), page, total_pages
        page += 1
      end
    rescue JSON::ParserError => e
      raise BlockedError, "Non-JSON posts response (possible challenge page): #{e.message}"
    end

    def each_tag
      page = 1
      loop do
        items = @http.get_json("#{BASE}/tags?per_page=100&page=#{page}&_fields=id,name,slug")
        items.each { |t| yield t }
        break if items.size < 100
        page += 1
      end
    end

    private

    def posts_url(category_id, modified_after, per_page, page)
      q = { categories: category_id, per_page: per_page, page: page, _fields: POST_FIELDS.join(",") }
      if modified_after
        q.merge!(modified_after: modified_after.utc.iso8601, orderby: "modified", order: "asc")
      end
      "#{BASE}/posts?#{URI.encode_www_form(q)}"
    end
  end
end
