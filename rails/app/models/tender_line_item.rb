class TenderLineItem < ApplicationRecord
  belongs_to :tender

  validates :tender_id, presence: true
  validates :quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :rate, presence: true, numericality: { greater_than_or_equal_to: 0 }

  enum section_category: {
    "Blank" => "Blank",
    "Steel Sections" => "Steel Sections",
    "Paintwork" => "Paintwork",
    "Bolts" => "Bolts",
    "Gutter Meter" => "Gutter Meter",
    "M16 Mechanical Anchor" => "M16 Mechanical Anchor",
    "M16 Chemical" => "M16 Chemical",
    "M20 Chemical" => "M20 Chemical",
    "M24 Chemical" => "M24 Chemical",
    "M16 HD Bolt" => "M16 HD Bolt",
    "M20 HD Bolt" => "M20 HD Bolt",
    "M24 HD Bolt" => "M24 HD Bolt",
    "M30 HD Bolt" => "M30 HD Bolt",
    "M36 HD Bolt" => "M36 HD Bolt",
    "M42 HD Bolt" => "M42 HD Bolt"
  }

  # Calculate the total amount for this line item
  def total_amount
    quantity * rate
  end
end
