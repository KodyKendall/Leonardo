class PreliminariesGeneralItemTemplate < ApplicationRecord
  enum :category, {
    fixed_based: 'fixed_based',
    duration_based: 'duration_based',
    percentage_based: 'percentage_based'
  }

  validates :category, presence: true
  validates :description, presence: true
  validates :quantity, numericality: { greater_than: 0 }
  validates :rate, numericality: { greater_than_or_equal_to: 0 }
end
