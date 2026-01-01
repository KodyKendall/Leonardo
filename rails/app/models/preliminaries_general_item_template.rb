class PreliminariesGeneralItemTemplate < ApplicationRecord
  enum :category, {
    fixed_based: 'fixed_based',
    duration_based: 'duration_based',
    percentage_based: 'percentage_based'
  }

  validates :category, presence: true
  validates :description, presence: true
end
