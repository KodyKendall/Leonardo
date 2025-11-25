class TenderLineItem < ApplicationRecord
  belongs_to :tender

  validates :tender_id, presence: true
  validates :quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :rate, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Calculate the total amount for this line item
  def total_amount
    quantity * rate
  end
end
