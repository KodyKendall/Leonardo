class RateBuildupCustomItem < ApplicationRecord
  belongs_to :line_item_rate_build_up

  validates :description, presence: true, length: { maximum: 255 }
  validates :rate, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :included, presence: true, numericality: { greater_than_or_equal_to: 0.01, less_than_or_equal_to: 5.0 }

  scope :ordered, -> { order(:sort_order, :created_at) }

  def amount
    (rate || 0).to_f * (included || 1.0).to_f
  end
end
