require 'rails_helper'

RSpec.describe LineItemMaterialTemplate, type: :model do
  describe "associations" do
    it { should belong_to(:section_category_template) }
    it { should belong_to(:material_supply).optional }
  end

  describe "validations" do
    it { should validate_numericality_of(:proportion_percentage).is_greater_than_or_equal_to(0).is_less_than_or_equal_to(100).allow_nil }
    it { should validate_numericality_of(:waste_percentage).is_greater_than_or_equal_to(0).is_less_than_or_equal_to(100).allow_nil }
  end
end
