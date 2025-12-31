require 'rails_helper'

RSpec.describe "preliminaries_general_items/show", type: :view do
  before(:each) do
    assign(:preliminaries_general_item, PreliminariesGeneralItem.create!(
      tender: nil,
      category: "Category",
      description: "MyText",
      quantity: "9.99",
      rate: "9.99",
      sort_order: 2
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(/Category/)
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/2/)
  end
end
