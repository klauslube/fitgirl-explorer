class ScrapeRun < ApplicationRecord
  KINDS = %w[full incremental comments].freeze

  validates :kind, inclusion: { in: KINDS }
  validates :status, inclusion: { in: %w[running succeeded failed] }

  scope :succeeded, -> { where(status: "succeeded") }

  def self.last_success_started_at(kind)
    succeeded.where(kind: kind).maximum(:started_at)
  end

  def self.track(kind)
    run = create!(kind: kind, started_at: Time.current)
    stats = Hash.new(0)
    yield stats
    run.update!(status: "succeeded", finished_at: Time.current, stats: stats)
    run
  rescue => e
    run&.update(status: "failed", finished_at: Time.current, stats: stats, error: "#{e.class}: #{e.message}")
    raise
  end
end
