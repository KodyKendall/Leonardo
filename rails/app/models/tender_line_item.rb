class TenderLineItem < ApplicationRecord
  belongs_to :tender, touch: true
  has_one :line_item_rate_build_up, dependent: :destroy
  has_one :line_item_material_breakdown, dependent: :destroy
  has_many :line_item_materials, dependent: :destroy

  accepts_nested_attributes_for :line_item_rate_build_up, allow_destroy: true
  accepts_nested_attributes_for :line_item_material_breakdown, allow_destroy: true

  validates :tender_id, presence: true
  validates :quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :rate, presence: true, numericality: { greater_than_or_equal_to: 0 }

  after_initialize :build_defaults, if: :new_record?
  after_create :create_line_item_rate_build_up, if: -> { line_item_rate_build_up.nil? }
  after_create :create_line_item_material_breakdown, if: -> { line_item_material_breakdown.nil? }
  after_save :update_tender_grand_total
  after_destroy :update_tender_grand_total

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

  private

  def update_tender_grand_total
    tender.recalculate_grand_total!
  end

  def build_defaults
    build_line_item_rate_build_up unless line_item_rate_build_up
    build_line_item_material_breakdown unless line_item_material_breakdown
  end

  def create_line_item_rate_build_up
    LineItemRateBuildUp.create!(tender_line_item_id: id) unless line_item_rate_build_up
  end

  def create_line_item_material_breakdown
    LineItemMaterialBreakdown.create!(tender_line_item_id: id) unless line_item_material_breakdown
  end
end
