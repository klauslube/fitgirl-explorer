require "digest"

module Fitgirl
  # Comment counts live in the third-party Tolstoy widget used by the source site, not in WordPress.
  # The widget itself calls this (undocumented) endpoint from every visitor's browser.
  # Keep all knowledge of it in this class.
  class TolstoyClient
    ENDPOINT = "https://web.tolstoycomments.com/api/chat/countcomment".freeze
    SITE_ID = 6289
    SITE_HOST = "fitgirl-repacks.site".freeze
    BATCH_SIZE = 100

    def initialize(http: Http.new)
      @http = http
    end

    def self.key_for(slug)
      Digest::MD5.hexdigest("#{SITE_HOST}/#{slug}/")
    end

    # slugs => { slug => count }. Slugs the service does not list have no comments (0).
    def counts(slugs)
      slugs.each_slice(BATCH_SIZE).each_with_object({}) do |batch, result|
        keys = batch.index_by { |slug| self.class.key_for(slug) }
        data = fetch(keys.keys)
        keys.each { |key, slug| result[slug] = Integer(data.fetch(key, 0)) }
      end
    end

    private

    def fetch(keys)
      query = ([ "siteId=#{SITE_ID}" ] + keys.map { |k| "h=#{k}" }).join("&")
      body = @http.get_json("#{ENDPOINT}?#{query}")
      hashas = body.dig("data", "hashas")
      raise Error, "Unexpected Tolstoy response shape: #{body.to_s[0, 200]}" unless hashas.is_a?(Hash)
      hashas
    end
  end
end
