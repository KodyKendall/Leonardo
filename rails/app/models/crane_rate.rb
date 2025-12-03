class CraneRate < ApplicationRecord
  validates :size, presence: true
  validates :ownership_type, presence: true, inclusion: { in: %w(rsb_owned rental) }
  validates :dry_rate_per_day, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :diesel_per_day, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :effective_from, presence: true

  # Business logic: wet rate = dry rate + diesel
  def wet_rate_per_day
    dry_rate_per_day + diesel_per_day
  end
end
