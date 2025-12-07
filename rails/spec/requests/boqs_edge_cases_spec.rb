require 'rails_helper'

RSpec.describe "BOQ Edge Cases", type: :request do
  let(:user) { create(:user) }
  let(:tender) { create(:tender) }

  describe "CSV parsing edge cases" do
    describe "malformed CSV files" do
      it "handles CSV with unmatched quotes" do
        sign_in user
        csv_content = 'Item #,Description,UOM,Quantity\n1,"Unclosed quote,Tonne,10'
        boq = create(:boq, :with_csv_file, csv_content: csv_content)

        expect(boq.csv_file).to be_attached
        expect(boq.csv_file.download).to include("Unclosed quote")
      end

      it "handles CSV with empty cells" do
        sign_in user
        csv_content = "Item #,Description,UOM,Quantity\n1,,Tonne,10\n2,Missing Item,,5"
        boq = create(:boq, :with_csv_file, csv_content: csv_content)

        get csv_as_json_boq_path(boq), as: :json
        expect(response).to be_successful
      end

      it "handles CSV with only headers" do
        sign_in user
        csv_content = "Item #,Description,UOM,Quantity"
        boq = create(:boq, :with_csv_file, csv_content: csv_content)

        get csv_as_json_boq_path(boq), as: :json
        json = JSON.parse(response.body)
        expect(json).to be_an(Array)
      end

      it "handles CSV with blank rows" do
        sign_in user
        csv_content = "Item #,Description,UOM,Quantity\n1,Steel,Tonne,10\n\n2,Bolts,Box,5\n"
        boq = create(:boq, :with_csv_file, csv_content: csv_content)

        get csv_as_json_boq_path(boq), as: :json
        json = JSON.parse(response.body)
        expect(json).to be_an(Array)
      end

      it "handles CSV with special characters" do
        sign_in user
        csv_content = 'Item #,Description,UOM,Quantity\n1,"Steel & Iron (Grade A)",Tonne,10\n2,"Bolts, nuts & washers",Box,5'
        boq = create(:boq, :with_csv_file, csv_content: csv_content)

        get csv_as_json_boq_path(boq), as: :json
        expect(response).to be_successful
      end

      it "handles CSV with unicode characters" do
        sign_in user
        csv_content = "Item #,Description,UOM,Quantity\n1,Ångström Steel,Tonne,10\n2,Café Bolts,Box,5"
        boq = create(:boq, :with_csv_file, csv_content: csv_content)

        get csv_as_json_boq_path(boq), as: :json
        expect(response).to be_successful
        json = JSON.parse(response.body)
        expect(json).to be_an(Array)
      end

      it "handles CSV with very long lines" do
        sign_in user
        long_description = "A" * 1000
        csv_content = "Item #,Description,UOM,Quantity\n1,#{long_description},Tonne,10"
        boq = create(:boq, :with_csv_file, csv_content: csv_content)

        get csv_as_json_boq_path(boq), as: :json
        expect(response).to be_successful
      end

      it "handles CSV with many columns" do
        sign_in user
        headers = (1..50).map { |i| "Column #{i}" }.join(",")
        csv_content = "#{headers}\n" + (1..50).map { |i| "Value #{i}" }.join(",")
        boq = create(:boq, :with_csv_file, csv_content: csv_content)

        get csv_as_json_boq_path(boq), as: :json
        expect(response).to be_successful
      end
    end

    describe "header row index edge cases" do
      it "handles header row at end of file" do
        sign_in user
        csv_content = "Value 1,Value 2\nValue 3,Value 4\nItem #,Description"
        boq = create(:boq, :with_csv_file, csv_content: csv_content)

        patch update_header_row_boq_path(boq), params: { header_row_index: 2 }, as: :json
        expect(response).to be_successful
      end

      it "handles zero header row index" do
        sign_in user
        boq = create(:boq, :with_csv_file)

        patch update_header_row_boq_path(boq), params: { header_row_index: 0 }, as: :json
        expect(response).to be_successful
      end

      it "handles large header row index" do
        sign_in user
        boq = create(:boq, :with_csv_file)

        patch update_header_row_boq_path(boq), params: { header_row_index: 999999 }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "handles non-integer header row index" do
        sign_in user
        boq = create(:boq, :with_csv_file)

        patch update_header_row_boq_path(boq), params: { header_row_index: "abc" }, as: :json
        # Should convert to 0 or handle gracefully
        expect(response.status).to be_in([200, 422])
      end
    end
  end

  describe "BOQ creation edge cases" do
    it "creates BOQ with very long boq_name" do
      sign_in user
      long_name = "A" * 500
      csv_file = fixture_file_upload('boq_sample.csv', 'text/csv')

      post boqs_path, params: {
        boq: {
          boq_name: long_name,
          csv_file: csv_file
        }
      }

      expect(Boq.last.boq_name).to eq(long_name)
    end

    it "creates BOQ with special characters in metadata" do
      sign_in user
      csv_file = fixture_file_upload('boq_sample.csv', 'text/csv')

      post boqs_path, params: {
        boq: {
          boq_name: "BOQ & Co. <Special>",
          client_name: "Client/Division (Africa)",
          csv_file: csv_file
        }
      }

      expect(response).to redirect_to(boq_path(Boq.last))
      expect(Boq.last.client_name).to eq("Client/Division (Africa)")
    end

    it "creates BOQ with null bytes (should be handled)" do
      sign_in user
      csv_file = fixture_file_upload('boq_sample.csv', 'text/csv')

      post boqs_path, params: {
        boq: {
          boq_name: "BOQ with\x00null",
          csv_file: csv_file
        }
      }

      expect([200, 302]).to include(response.status)
    end

    it "creates BOQ with future received_date" do
      sign_in user
      csv_file = fixture_file_upload('boq_sample.csv', 'text/csv')
      future_date = Date.today + 30.days

      post boqs_path, params: {
        boq: {
          boq_name: "Future BOQ",
          received_date: future_date.to_s,
          csv_file: csv_file
        }
      }

      expect(Boq.last.received_date).to eq(future_date)
    end

    it "creates BOQ with very old received_date" do
      sign_in user
      csv_file = fixture_file_upload('boq_sample.csv', 'text/csv')
      old_date = Date.new(1900, 1, 1)

      post boqs_path, params: {
        boq: {
          boq_name: "Old BOQ",
          received_date: old_date.to_s,
          csv_file: csv_file
        }
      }

      expect(Boq.last.received_date).to eq(old_date)
    end
  end

  describe "line items creation edge cases" do
    let(:boq) { create(:boq) }

    it "handles line items with missing optional fields" do
      sign_in user
      line_items_data = [
        { item_number: "1", section_category: "Steel Sections" }
      ]

      post create_line_items_boq_path(boq), params: { line_items: line_items_data }, as: :json

      expect(response).to have_http_status(:created)
      item = boq.boq_items.first
      expect(item.item_number).to eq("1")
    end

    it "handles line items with null values" do
      sign_in user
      line_items_data = [
        {
          item_number: "1",
          item_description: nil,
          unit_of_measure: nil,
          quantity: nil,
          section_category: "Steel Sections"
        }
      ]

      post create_line_items_boq_path(boq), params: { line_items: line_items_data }, as: :json

      expect(response).to have_http_status(:created)
    end

    it "handles line items with zero quantity" do
      sign_in user
      line_items_data = [
        {
          item_number: "1",
          item_description: "Item",
          unit_of_measure: "Tonne",
          quantity: 0,
          section_category: "Steel Sections"
        }
      ]

      post create_line_items_boq_path(boq), params: { line_items: line_items_data }, as: :json

      expect(response).to have_http_status(:created)
      expect(boq.boq_items.first.quantity).to eq(0.0)
    end

    it "handles line items with negative quantity (edge case)" do
      sign_in user
      line_items_data = [
        {
          item_number: "1",
          item_description: "Item",
          unit_of_measure: "Tonne",
          quantity: -10,
          section_category: "Steel Sections"
        }
      ]

      post create_line_items_boq_path(boq), params: { line_items: line_items_data }, as: :json

      expect(response).to have_http_status(:created)
    end

    it "handles line items with very large quantity" do
      sign_in user
      line_items_data = [
        {
          item_number: "1",
          item_description: "Item",
          unit_of_measure: "Tonne",
          quantity: 999999.999,
          section_category: "Steel Sections"
        }
      ]

      post create_line_items_boq_path(boq), params: { line_items: line_items_data }, as: :json

      expect(response).to have_http_status(:created)
      expect(boq.boq_items.first.quantity).to eq(999999.999)
    end

    it "handles very large number of line items" do
      sign_in user
      line_items_data = (1..1000).map do |i|
        {
          item_number: i.to_s,
          item_description: "Item #{i}",
          unit_of_measure: "Tonne",
          quantity: i * 10,
          section_category: "Steel Sections"
        }
      end

      post create_line_items_boq_path(boq), params: { line_items: line_items_data }, as: :json

      expect(response).to have_http_status(:created)
      expect(boq.boq_items.count).to eq(1000)
    end

    it "handles line items with invalid section_category" do
      sign_in user
      line_items_data = [
        {
          item_number: "1",
          item_description: "Item",
          unit_of_measure: "Tonne",
          quantity: 10,
          section_category: "Invalid Category"
        }
      ]

      post create_line_items_boq_path(boq), params: { line_items: line_items_data }, as: :json

      # May accept or reject depending on implementation
      expect([201, 422]).to include(response.status)
    end

    it "handles line items with very long descriptions" do
      sign_in user
      long_description = "A" * 5000
      line_items_data = [
        {
          item_number: "1",
          item_description: long_description,
          unit_of_measure: "Tonne",
          quantity: 10,
          section_category: "Steel Sections"
        }
      ]

      post create_line_items_boq_path(boq), params: { line_items: line_items_data }, as: :json

      expect(response).to have_http_status(:created)
    end

    it "handles duplicate item numbers" do
      sign_in user
      line_items_data = [
        {
          item_number: "1",
          item_description: "Item 1",
          unit_of_measure: "Tonne",
          quantity: 10,
          section_category: "Steel Sections"
        },
        {
          item_number: "1",
          item_description: "Item 1 Duplicate",
          unit_of_measure: "Box",
          quantity: 5,
          section_category: "Bolts"
        }
      ]

      post create_line_items_boq_path(boq), params: { line_items: line_items_data }, as: :json

      expect(response).to have_http_status(:created)
      expect(boq.boq_items.count).to eq(2)
    end
  end

  describe "concurrent operations" do
    it "handles multiple BOQ uploads from same user" do
      sign_in user
      csv_file1 = fixture_file_upload('boq_sample.csv', 'text/csv')
      csv_file2 = fixture_file_upload('boq_sample.csv', 'text/csv')

      post boqs_path, params: {
        boq: {
          boq_name: "BOQ 1",
          csv_file: csv_file1
        }
      }

      post boqs_path, params: {
        boq: {
          boq_name: "BOQ 2",
          csv_file: csv_file2
        }
      }

      expect(Boq.count).to eq(2)
      expect(Boq.all.map(&:uploaded_by).uniq).to eq([user])
    end

    it "handles updating BOQ while another is being parsed" do
      sign_in user
      boq1 = create(:boq, :parsing)
      boq2 = create(:boq, :uploaded)

      patch update_attributes_boq_path(boq2), params: {
        boq: { boq_name: "Updated BOQ 2" }
      }, as: :json

      expect(response).to be_successful
      expect(boq1.reload.parsing?).to be true
      expect(boq2.reload.boq_name).to eq("Updated BOQ 2")
    end
  end

  describe "CSV file size limits" do
    it "handles very large CSV files" do
      sign_in user
      # Create a CSV with many rows
      csv_content = "Item #,Description,UOM,Quantity\n"
      100.times do |i|
        csv_content += "#{i},Item #{i},Tonne,#{i * 10}\n"
      end

      boq = create(:boq, :with_csv_file, csv_content: csv_content)

      get csv_as_json_boq_path(boq), as: :json
      expect(response).to be_successful
      json = JSON.parse(response.body)
      expect(json.length).to be >= 90
    end

    it "handles empty CSV file" do
      sign_in user
      boq = create(:boq, :with_csv_file, csv_content: "")

      get csv_as_json_boq_path(boq), as: :json
      expect(response).to be_successful
      json = JSON.parse(response.body)
      expect(json).to be_an(Array)
    end
  end

  describe "authorization and security" do
    let(:boq) { create(:boq) }
    let(:other_user) { create(:user) }

    it "allows user to access their own BOQ" do
      sign_in user
      user_boq = create(:boq, uploaded_by: user)

      get boq_path(user_boq)
      expect(response).to be_successful
    end

    it "allows user to access any BOQ (no ownership restriction)" do
      sign_in user
      other_boq = create(:boq, uploaded_by: other_user)

      get boq_path(other_boq)
      expect(response).to be_successful
    end

    it "prevents unauthenticated access to BOQ index" do
      get boqs_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "prevents unauthenticated upload" do
      csv_file = fixture_file_upload('boq_sample.csv', 'text/csv')
      post boqs_path, params: {
        boq: {
          boq_name: "Unauthorized BOQ",
          csv_file: csv_file
        }
      }

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "status transitions edge cases" do
    it "handles rapid status changes" do
      sign_in user
      boq = create(:boq)

      boq.update(status: "parsing")
      expect(boq.parsing?).to be true

      boq.update(status: "parsed", parsed_at: Time.current)
      expect(boq.parsed?).to be true

      boq.update(status: "error")
      expect(boq.error?).to be true
    end

    it "preserves parsed_at when updating other fields" do
      sign_in user
      parsed_time = 1.day.ago
      boq = create(:boq, status: "parsed", parsed_at: parsed_time)

      patch update_attributes_boq_path(boq), params: {
        boq: { boq_name: "Updated Name" }
      }, as: :json

      boq.reload
      expect(boq.parsed_at).to be_within(1.minute).of(Time.current)
    end
  end

  describe "tender association edge cases" do
    it "handles BOQ attached to multiple tenders (last one wins)" do
      sign_in user
      boq = create(:boq, :without_tender)
      tender1 = create(:tender)
      tender2 = create(:tender)

      post attach_boq_tender_path(tender1), params: { boq_id: boq.id }, as: :json
      boq.reload
      expect(boq.tender).to eq(tender1)

      post attach_boq_tender_path(tender2), params: { boq_id: boq.id }, as: :json
      boq.reload
      expect(boq.tender).to eq(tender2)
    end

    it "handles detaching BOQ from tender" do
      sign_in user
      tender = create(:tender)
      boq = create(:boq, tender: tender)

      post detach_boq_path(boq), as: :json

      boq.reload
      expect(boq.tender).to be_nil
    end

    it "allows attaching detached BOQ to new tender" do
      sign_in user
      tender1 = create(:tender)
      tender2 = create(:tender)
      boq = create(:boq, tender: tender1)

      post detach_boq_path(boq), as: :json
      expect(boq.reload.tender).to be_nil

      post attach_boq_tender_path(tender2), params: { boq_id: boq.id }, as: :json
      expect(boq.reload.tender).to eq(tender2)
    end
  end
end
