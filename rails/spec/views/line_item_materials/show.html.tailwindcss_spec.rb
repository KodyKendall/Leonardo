require 'rails_helper'

RSpec.describe "line_item_materials/show", type: :view do
  before(:each) do
    assign(:line_item_material, LineItemMaterial.create!(
      tender_line_item: nil,
      material_supply: nil,
      proportion: "9.99"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(/9.99/)
  end
end
