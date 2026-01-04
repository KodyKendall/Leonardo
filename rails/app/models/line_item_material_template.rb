class LineItemMaterialTemplate < ApplicationRecord
  belongs_to :section_category_template
  belongs_to :material_supply, optional: true

  validates :proportion_percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :waste_percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
end
