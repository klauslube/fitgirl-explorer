require "net/http"

module Fitgirl
  # Polite HTTP: fixed delay between requests, retries with backoff on transient failures.
  class Http
    USER_AGENT = "FitGirlExplorer/0.1 (personal metadata catalog; respects robots.txt)".freeze
    RETRYABLE = [ 429, 500, 502, 503, 504 ].freeze

    class << self
      attr_writer :delay, :max_retries, :base_backoff

      def delay = @delay ||= Float(ENV.fetch("FITGIRL_REQUEST_DELAY", 4))
      def max_retries = @max_retries ||= 4
      def base_backoff = @base_backoff ||= 2.0
    end

    def initialize(logger: Rails.logger, sleeper: Kernel.method(:sleep))
      @logger = logger
      @sleeper = sleeper
      @last_request_at = nil
    end

    # Returns the Net::HTTPResponse (2xx/3xx handled by caller); raises on failure.
    def get(url)
      uri = URI(url)
      attempt = 0
      begin
        throttle
        response = perform(uri)
        @last_request_at = monotonic
        check!(response, url)
        response
      rescue RequestError, Timeout::Error, SystemCallError, SocketError, OpenSSL::SSL::SSLError => e
        attempt += 1
        raise RequestError, "#{url}: #{e.message}" if attempt > self.class.max_retries
        wait = backoff_for(attempt, e)
        @logger.warn("[fitgirl] #{e.class}: #{e.message} - retry #{attempt}/#{self.class.max_retries} in #{wait}s")
        @sleeper.call(wait)
        retry
      end
    end

    def get_json(url)
      JSON.parse(get(url).body)
    rescue JSON::ParserError => e
      raise BlockedError, "Non-JSON response from #{url} (possible challenge page): #{e.message}"
    end

    private

    def perform(uri)
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout: 30) do |http|
        http.request(Net::HTTP::Get.new(uri, "User-Agent" => USER_AGENT, "Accept" => "application/json"))
      end
    end

    def check!(response, url)
      code = response.code.to_i
      return if code < 400
      raise BlockedError, "HTTP #{code} for #{url} (blocked, not retrying)" if code == 403
      raise RetryableStatus.new(code, response["Retry-After"]) if RETRYABLE.include?(code)
      raise BlockedError, "HTTP #{code} for #{url}"
    end

    class RetryableStatus < RequestError
      attr_reader :retry_after
      def initialize(code, retry_after)
        @retry_after = retry_after
        super("HTTP #{code}")
      end
    end

    def backoff_for(attempt, error)
      hinted = error.respond_to?(:retry_after) && error.retry_after.to_f
      hinted.to_f.positive? ? hinted : self.class.base_backoff**attempt
    end

    def throttle
      return unless @last_request_at
      remaining = self.class.delay - (monotonic - @last_request_at)
      @sleeper.call(remaining) if remaining.positive?
    end

    def monotonic = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end
end
