require 'rails_helper'

RSpec.describe "TenderLineItems", type: :request do
  let(:user) { create(:user) }
  let(:tender) { create(:tender) }
  let(:section_category) { create(:section_category) }

  before { sign_in(user) }

  describe "POST /tenders/:tender_id/tender_line_items (instant create without params)" do
    context "when requesting turbo_stream format without parameters" do
      it "creates the line item with defaults instead of crashing" do
        # Arrange: Create a tender and section category
        tender
        section_category

        # Act: Send POST request to create a tender line item
        # with turbo_stream format but NO parameters (instant create)
        post "/tenders/#{tender.id}/tender_line_items",
             headers: { "Accept" => "text/vnd.turbo-stream.html" },
             params: {}

        # Assert: It should now succeed because we added default section_category_id
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("text/vnd.turbo-stream")
        expect(response.body).to include("turbo-stream action=\"append\" target=\"line_items_container\"")
      end
    end

    context "when validation fails" do
      it "should gracefully handle validation error in turbo_stream format" do
        # Arrange: Create a tender
        tender
        
        # To trigger a validation error even with our new defaults, 
        # we can explicitly pass an invalid value or mock the save failure.
        # Here we'll pass an invalid quantity.
        post "/tenders/#{tender.id}/tender_line_items",
             headers: { "Accept" => "text/vnd.turbo-stream.html" },
             params: { tender_line_item: { quantity: -1 } }

        # Assert: Should return 422 with turbo_stream response
        # NOT crash with ActionView::MissingTemplate
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to include("text/vnd.turbo-stream")
        expect(response.body).to include("turbo-stream action=\"update\" target=\"flash\"")
      end
    end

    context "when turbo_stream format is explicitly requested" do
      it "does not raise MissingTemplate error" do
        tender

        # Act & Assert: Should NOT raise MissingTemplate
        expect {
          post "/tenders/#{tender.id}/tender_line_items",
               headers: { "Accept" => "text/vnd.turbo-stream.html" },
               params: {}
        }.not_to raise_error
      end
    end
  end

  describe "PATCH /tenders/:tender_id/tender_line_items/:id" do
    let!(:line_item) { create(:tender_line_item, tender: tender, quantity: 10, include_in_tonnage: true) }

    it "updates include_in_tonnage and recalculates tender tonnage" do
      expect(tender.reload.total_tonnage).to eq(10)

      patch "/tenders/#{tender.id}/tender_line_items/#{line_item.id}",
            headers: { "Accept" => "text/vnd.turbo-stream.html" },
            params: { tender_line_item: { include_in_tonnage: false } }

      expect(response).to have_http_status(:ok)
      expect(line_item.reload.include_in_tonnage).to be false
      expect(tender.reload.total_tonnage).to eq(0)
    end

    it "updates section_category_id and preserves open_breakdown state" do
      category2 = create(:section_category)
      
      patch "/tenders/#{tender.id}/tender_line_items/#{line_item.id}",
            headers: { "Accept" => "text/vnd.turbo-stream.html" },
            params: { 
              tender_line_item: { section_category_id: category2.id },
              open_breakdown: "true"
            }

      expect(response).to have_http_status(:ok)
      expect(line_item.reload.section_category_id).to eq(category2.id)
      # Check that the checkbox in the response is checked
      expect(response.body).to include('checked="checked"')
    end
  end
end
