require 'rails_helper'

RSpec.describe "line_item_material_templates/show", type: :view do
  before(:each) do
    assign(:line_item_material_template, LineItemMaterialTemplate.create!(
      section_category_template: nil,
      material_supply: nil,
      proportion_percentage: "9.99",
      waste_percentage: "9.99",
      sort_order: 2
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/2/)
  end
end
