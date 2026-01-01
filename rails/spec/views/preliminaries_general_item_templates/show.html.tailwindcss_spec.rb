require 'rails_helper'

RSpec.describe "preliminaries_general_item_templates/show", type: :view do
  before(:each) do
    assign(:preliminaries_general_item_template, PreliminariesGeneralItemTemplate.create!(
      category: "Category",
      description: "MyText",
      quantity: "9.99",
      rate: "9.99",
      sort_order: 2,
      is_crane: false,
      is_access_equipment: false
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Category/)
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
  end
end
