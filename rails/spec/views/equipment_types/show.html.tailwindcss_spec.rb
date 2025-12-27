require 'rails_helper'

RSpec.describe "equipment_types/show", type: :view do
  before(:each) do
    assign(:equipment_type, EquipmentType.create!(
      category: "Category",
      model: "Model",
      working_height_m: "9.99",
      base_rate_monthly: "9.99",
      damage_waiver_pct: "9.99",
      diesel_allowance_monthly: "9.99",
      is_active: false
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Category/)
    expect(rendered).to match(/Model/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/false/)
  end
end
