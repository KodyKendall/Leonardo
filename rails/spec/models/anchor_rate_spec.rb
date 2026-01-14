require 'rails_helper'

RSpec.describe AnchorRate, type: :model do
  describe "associations" do
    it { should have_many(:anchor_supplier_rates).dependent(:destroy) }
    it { should have_many(:suppliers).through(:anchor_supplier_rates) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_numericality_of(:waste_percentage).is_greater_than_or_equal_to(0) }
    it { should validate_numericality_of(:material_cost).is_greater_than_or_equal_to(0) }
  end
end
