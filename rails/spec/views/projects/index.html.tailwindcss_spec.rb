require 'rails_helper'

RSpec.describe "projects/index", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
    @projects = [create(:project), create(:project)]
    assign(:projects, @projects)
  end

  it "renders a list of projects" do
    render
    @projects.each do |project|
      expect(rendered).to match(/#{Regexp.escape(project.rsb_number)}/)
      expect(rendered).to match(/#{Regexp.escape(project.project_status)}/)
    end
  end
end
