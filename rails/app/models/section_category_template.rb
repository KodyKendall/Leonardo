class SectionCategoryTemplate < ApplicationRecord
  belongs_to :section_category
  has_many :line_item_material_templates, dependent: :destroy
end
