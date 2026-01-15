require 'rails_helper'

RSpec.describe "Add Material Bug Reproduction", type: :request do
  let(:user) { create(:user) }
  let(:tender) { create(:tender) }
  let(:tender_line_item) { create(:tender_line_item, tender: tender) }
  let(:breakdown) { create(:line_item_material_breakdown, tender_line_item: tender_line_item) }

  before do
    sign_in user
  end

  describe "POST /line_item_materials" do
    let(:params) do
      {
        line_item_material: {
          line_item_material_breakdown_id: breakdown.id,
          material_supply_type: "MaterialSupply",
          proportion_percentage: 100
        }
      }
    end

    context "when format is HTML" do
      it "redirects back to the tender builder instead of the standalone breakdown page" do
        builder_url = builder_tender_url(tender)
        post line_item_materials_path(format: :html), params: params, headers: { "HTTP_REFERER" => builder_url }
        
        # This FAILS when bug exists (redirects to breakdown path)
        # and PASSES when fixed (redirects back to builder)
        expect(response).to redirect_to(builder_url + "?open_breakdown=#{tender_line_item.id}")
      end
    end

    context "when format is Turbo Stream" do
      it "returns turbo stream responses" do
        post line_item_materials_path(format: :turbo_stream), params: params
        
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include("<turbo-stream action=\"append\" target=\"line_item_materials_container_#{breakdown.id}\">")
        expect(response.body).to include("<turbo-stream action=\"update\" target=\"material_breakdown_totals_#{breakdown.id}\">")
      end
    end
  end
end
