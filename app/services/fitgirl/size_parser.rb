module Fitgirl
  # Turns the free text used in posts ("11.4 GB", "3,3 GB", "2.1/2.3 GB", "from 2.6 GB [Selective Download]")
  # into bytes. Returns [min, max] or nil when nothing numeric is found.
  module SizeParser
    UNITS = { "KB" => 1024, "MB" => 1024**2, "GB" => 1024**3, "TB" => 1024**4 }.freeze
    NUMBER = /\d+(?:[.,]\d+)?/
    PATTERN = /(#{NUMBER}(?:\s*\/\s*#{NUMBER})*)\s*(KB|MB|GB|TB)\b/i

    def self.call(text)
      match = PATTERN.match(text.to_s)
      return unless match

      factor = UNITS.fetch(match[2].upcase)
      values = match[1].split("/").map { |n| (n.strip.tr(",", ".").to_f * factor).round }
      [ values.min, values.max ]
    end
  end
end
