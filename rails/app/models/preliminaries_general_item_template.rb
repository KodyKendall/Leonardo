class PreliminariesGeneralItemTemplate < ApplicationRecord
  has_many :preliminaries_general_items, dependent: :nullify

  enum :category, {
    fixed: 'fixed',
    time_based: 'time_based',
    percentage_based: 'percentage_based'
  }

  validates :category, presence: true
  validates :description, presence: true
  validates :quantity, numericality: { greater_than: 0 }
  validates :rate, numericality: { greater_than_or_equal_to: 0 }
end
