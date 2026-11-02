module Fitgirl
  # Strips version / DLC suffixes so searching and sorting by name behaves.
  # "Deep Rock Galactic: Deluxe Edition, v1.40.158958.0 + 13 DLCs/Bonuses" -> "deep rock galactic: deluxe edition"
  module TitleNormalizer
    SUFFIXES = [
      /,\s*v?\d[\w.\-]*(\s*\+.*)?\z/i,         # ", v1.40.158958.0 + 13 DLCs"
      /\s+[-–]\s+v\d[\w.\-]*(\s*\+.*)?\z/i,    # " – v1.2"
      /\s*\+\s*\d*\s*(DLCs?|Bonus(es)?|Bonus OST|Soundtrack).*\z/i
    ].freeze

    def self.call(title)
      text = title.to_s.dup
      SUFFIXES.each { |re| text = text.sub(re, "") }
      I18n.transliterate(text).downcase.squish
    end
  end
end
