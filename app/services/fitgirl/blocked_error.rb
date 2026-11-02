module Fitgirl
  # Raised on 403 / challenge pages. We never retry or try to bypass protection.
  class BlockedError < Error; end
end
