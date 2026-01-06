require 'rails_helper'

RSpec.describe SectionCategoryTemplate, type: :model do
  describe "associations" do
    it { should belong_to(:section_category) }
    it { should have_many(:line_item_material_templates).dependent(:destroy) }
  end
end
