require 'rails_helper'

RSpec.describe "projects/show", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
    @project = create(:project)
    assign(:project, @project)
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/#{@project.rsb_number}/)
    expect(rendered).to match(/#{@project.project_status}/)
  end
end
