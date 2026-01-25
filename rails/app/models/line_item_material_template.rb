class LineItemMaterialTemplate < ApplicationRecord
  belongs_to :section_category_template
  belongs_to :material_supply, polymorphic: true, optional: true

  delegate :section_category, to: :section_category_template, allow_nil: true
  delegate :quantity_based?, to: :section_category, allow_nil: true

  validates :proportion_percentage, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :proportion_percentage, numericality: { less_than_or_equal_to: 100 }, allow_nil: true, unless: :quantity_based?
  validates :waste_percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
end
