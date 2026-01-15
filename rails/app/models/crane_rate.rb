class CraneRate < ApplicationRecord
  OWNERSHIP_TYPES = {
    "RSB Owned" => "rsb_owned",
    "Rental" => "rental"
  }.freeze

  validates :size, presence: true, format: { with: /\A\d+t\z/, message: "must be in format like '10t' or '110t'" },
            uniqueness: { scope: :ownership_type, message: "combination already exists" }
  validates :ownership_type, presence: true, inclusion: { in: OWNERSHIP_TYPES.values }

  scope :ordered_by_size, -> {
    order(Arel.sql("CAST(NULLIF(regexp_replace(size, '[^0-9]', '', 'g'), '') AS INTEGER) ASC, ownership_type ASC"))
  }
  validates :dry_rate_per_day, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :diesel_per_day, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :effective_from, presence: true

  # Business logic: wet rate = dry rate + diesel
  def wet_rate_per_day
    dry_rate_per_day + diesel_per_day
  end
end
