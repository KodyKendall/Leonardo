require 'rails_helper'

RSpec.describe Boq, type: :model do
  include ActiveSupport::Testing::TimeHelpers
  describe "associations" do
    it { should belong_to(:tender).optional }
    it { should belong_to(:uploaded_by).class_name('User').optional }
    it { should have_many(:boq_items).dependent(:destroy) }
    it { should have_one_attached(:csv_file) }
  end

  describe "validations" do
    it { should validate_presence_of(:boq_name) }
    
    it "allows valid status values" do
      %w(uploaded parsing parsed error).each do |status|
        boq = build(:boq, status: status)
        expect(boq).to be_valid
      end
    end
  end

  describe "enums" do
    it "has status enum with correct values" do
      boq = create(:boq, status: "uploaded")
      expect(boq.uploaded?).to be true
      
      boq = create(:boq, status: "parsing")
      expect(boq.parsing?).to be true
      
      boq = create(:boq, status: "parsed")
      expect(boq.parsed?).to be true
      
      boq = create(:boq, status: "error")
      expect(boq.error?).to be true
    end
  end

  describe "creation" do
    it "creates a valid BOQ with minimum required fields" do
      user = create(:user)
      boq = create(:boq, boq_name: "Test BOQ", uploaded_by: user, tender: nil)
      
      expect(boq).to be_persisted
      expect(boq.boq_name).to eq("Test BOQ")
      expect(boq.uploaded_by).to eq(user)
      expect(boq.status).to eq("uploaded")
    end

    it "creates a BOQ with complete metadata" do
      user = create(:user)
      tender = create(:tender)
      boq = create(:boq,
        boq_name: "Client BOQ",
        client_name: "Acme Corp",
        client_reference: "ACM-2024",
        qs_name: "John Smith",
        received_date: Date.new(2024, 1, 15),
        notes: "Structural steel BOQ",
        uploaded_by: user,
        tender: tender
      )

      expect(boq.boq_name).to eq("Client BOQ")
      expect(boq.client_name).to eq("Acme Corp")
      expect(boq.client_reference).to eq("ACM-2024")
      expect(boq.qs_name).to eq("John Smith")
      expect(boq.received_date).to eq(Date.new(2024, 1, 15))
      expect(boq.notes).to eq("Structural steel BOQ")
      expect(boq.tender).to eq(tender)
    end

    it "creates a BOQ without a tender" do
      user = create(:user)
      boq = create(:boq, uploaded_by: user, tender: nil)
      
      expect(boq.tender).to be_nil
    end
  end

  describe "status lifecycle" do
    let(:boq) { create(:boq) }

    it "starts with uploaded status" do
      expect(boq.status).to eq("uploaded")
      expect(boq.uploaded?).to be true
    end

    it "can transition from uploaded to parsing" do
      boq.update(status: "parsing")
      expect(boq.parsing?).to be true
    end

    it "can transition from parsing to parsed" do
      boq.update(status: "parsing")
      boq.update(status: "parsed", parsed_at: Time.current)
      
      expect(boq.parsed?).to be true
      expect(boq.parsed_at).to be_present
    end

    it "can transition to error status" do
      boq.update(status: "error")
      expect(boq.error?).to be true
    end

    it "tracks when BOQ was parsed" do
      boq.update(status: "parsed", parsed_at: Time.current)
      expect(boq.parsed_at).to be_within(1.second).of(Time.current)
    end
  end

  describe "CSV file attachment" do
    it "can attach a CSV file" do
      boq = create(:boq, :with_csv_file)
      expect(boq.csv_file).to be_attached
      expect(boq.csv_file.filename.to_s).to end_with('.csv')
    end

    it "handles BOQ without CSV file" do
      boq = create(:boq)
      expect(boq.csv_file).not_to be_attached
    end

    it "stores CSV file content correctly" do
      csv_content = "Item #,Description,UOM,Quantity\n1,Steel,Tonne,10\n2,Bolts,Box,5"
      boq = create(:boq, :with_csv_file, csv_content: csv_content)
      
      downloaded_content = boq.csv_file.download
      expect(downloaded_content).to include("Steel")
      expect(downloaded_content).to include("Bolts")
    end
  end

  describe "relationships with boq_items" do
    let(:boq) { create(:boq) }

    it "creates boq_items associated with the BOQ" do
      item1 = create(:boq_item, boq: boq, sequence_order: 1)
      item2 = create(:boq_item, boq: boq, sequence_order: 2)

      expect(boq.boq_items.count).to eq(2)
      expect(boq.boq_items).to include(item1, item2)
    end

    it "destroys boq_items when BOQ is deleted" do
      boq = create(:boq)
      create(:boq_item, boq: boq)
      create(:boq_item, boq: boq)

      expect(BoqItem.count).to eq(2)
      
      boq.destroy
      
      expect(BoqItem.count).to eq(0)
    end

    it "returns boq_items in sequence order" do
      boq = create(:boq)
      item3 = create(:boq_item, boq: boq, sequence_order: 3)
      item1 = create(:boq_item, boq: boq, sequence_order: 1)
      item2 = create(:boq_item, boq: boq, sequence_order: 2)

      ordered_items = boq.boq_items.order(:sequence_order)
      expect(ordered_items.pluck(:sequence_order)).to eq([1, 2, 3])
    end
  end

  describe "header_row_index" do
    it "defaults to 0" do
      boq = create(:boq)
      expect(boq.header_row_index).to eq(0)
    end

    it "can be updated to different values" do
      boq = create(:boq, header_row_index: 2)
      expect(boq.header_row_index).to eq(2)

      boq.update(header_row_index: 5)
      expect(boq.header_row_index).to eq(5)
    end
  end

  describe "file management" do
    it "stores file_name" do
      boq = create(:boq, file_name: "boq_2024_01.csv")
      expect(boq.file_name).to eq("boq_2024_01.csv")
    end

    it "stores file_path" do
      boq = create(:boq, file_path: "active_storage")
      expect(boq.file_path).to eq("active_storage")
    end

    it "can update file metadata" do
      boq = create(:boq)
      boq.update(file_name: "updated_boq.csv", file_path: "/new/path")
      
      expect(boq.file_name).to eq("updated_boq.csv")
      expect(boq.file_path).to eq("/new/path")
    end
  end

  describe "user tracking" do
    it "tracks which user uploaded the BOQ" do
      user = create(:user, email: "uploader@test.com")
      boq = create(:boq, uploaded_by: user)
      
      expect(boq.uploaded_by).to eq(user)
      expect(boq.uploaded_by.email).to eq("uploader@test.com")
    end

    it "can be uploaded without a user" do
      boq = create(:boq, uploaded_by: nil)
      expect(boq.uploaded_by).to be_nil
    end
  end

  describe "tender association" do
    it "associates BOQ with a tender" do
      tender = create(:tender)
      boq = create(:boq, tender: tender)
      
      expect(boq.tender).to eq(tender)
    end

    it "can exist without a tender" do
      boq = create(:boq, tender: nil)
      expect(boq.tender).to be_nil
    end

    it "can be attached to a tender after creation" do
      boq = create(:boq, tender: nil)
      tender = create(:tender)
      
      boq.update(tender: tender)
      
      expect(boq.tender).to eq(tender)
    end

    it "can be detached from a tender" do
      tender = create(:tender)
      boq = create(:boq, tender: tender)
      
      boq.update(tender: nil)
      
      expect(boq.tender).to be_nil
    end
  end

  describe "scopes and queries" do
    it "orders BOQs by creation date in reverse" do
      boq1 = create(:boq, boq_name: "BOQ 1")
      boq2 = create(:boq, boq_name: "BOQ 2")
      boq3 = create(:boq, boq_name: "BOQ 3")

      boqs = Boq.order(created_at: :desc)
      expect(boqs.pluck(:id)).to eq([boq3.id, boq2.id, boq1.id])
    end

    it "finds BOQs by status" do
      uploaded_boq = create(:boq, status: "uploaded")
      parsed_boq = create(:boq, status: "parsed")

      expect(Boq.where(status: "uploaded")).to include(uploaded_boq)
      expect(Boq.where(status: "parsed")).to include(parsed_boq)
      expect(Boq.where(status: "uploaded")).not_to include(parsed_boq)
    end
  end

  describe "traits" do
    it "creates a parsed BOQ with :parsed trait" do
      boq = create(:boq, :parsed)
      
      expect(boq.parsed?).to be true
      expect(boq.parsed_at).to be_present
    end

    it "creates a parsing BOQ with :parsing trait" do
      boq = create(:boq, :parsing)
      
      expect(boq.parsing?).to be true
    end

    it "creates an error BOQ with :error_state trait" do
      boq = create(:boq, :error_state)
      
      expect(boq.error?).to be true
    end

    it "creates a BOQ with CSV file using :with_csv_file trait" do
      boq = create(:boq, :with_csv_file)
      
      expect(boq.csv_file).to be_attached
    end

    it "creates a BOQ without tender using :without_tender trait" do
      boq = create(:boq, :without_tender)
      
      expect(boq.tender).to be_nil
    end
  end

  describe "timestamps" do
    it "records created_at timestamp" do
      boq = create(:boq)
      expect(boq.created_at).to be_present
    end

    it "records updated_at timestamp" do
      boq = create(:boq)
      original_updated_at = boq.updated_at
      
      travel 1.hour do
        boq.update(boq_name: "Updated BOQ")
      end
      
      expect(boq.updated_at).to be > original_updated_at
    end

    it "records parsed_at when marked as parsed" do
      boq = create(:boq)
      expect(boq.parsed_at).to be_nil
      
      boq.update(status: "parsed", parsed_at: Time.current)
      expect(boq.parsed_at).to be_present
    end
  end
end
