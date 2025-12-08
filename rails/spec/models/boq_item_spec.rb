require 'rails_helper'

RSpec.describe BoqItem, type: :model do
  include ActiveSupport::Testing::TimeHelpers
  describe "associations" do
    it { should belong_to(:boq) }
  end

  describe "validations" do
    it { should validate_presence_of(:boq_id) }
  end

  describe "enums" do
    it "has section_category enum with correct values" do
      categories = {
        blank: 'Blank',
        steel_sections: 'Steel Sections',
        paintwork: 'Paintwork',
        bolts: 'Bolts',
        gutter_meter: 'Gutter Meter',
        m16_mechanical_anchor: 'M16 Mechanical Anchor',
        m16_chemical: 'M16 Chemical',
        m20_chemical: 'M20 Chemical',
        m24_chemical: 'M24 Chemical',
        m16_hd_bolt: 'M16 HD Bolt',
        m20_hd_bolt: 'M20 HD Bolt',
        m24_hd_bolt: 'M24 HD Bolt',
        m30_hd_bolt: 'M30 HD Bolt',
        m36_hd_bolt: 'M36 HD Bolt',
        m42_hd_bolt: 'M42 HD Bolt'
      }

      categories.each do |key, value|
        item = create(:boq_item, section_category: value)
        expect(item.send("#{key}?")).to be true
      end
    end
  end

  describe "creation" do
    it "creates a valid BOQ item with minimum required fields" do
      boq = create(:boq)
      item = create(:boq_item, boq: boq)

      expect(item).to be_persisted
      expect(item.boq).to eq(boq)
    end

    it "creates a BOQ item with complete details" do
      boq = create(:boq)
      item = create(:boq_item,
        boq: boq,
        item_number: "ITEM-001",
        item_description: "Structural Steel - Universal Beam",
        unit_of_measure: "Tonne",
        quantity: 25.5,
        section_category: "Steel Sections",
        sequence_order: 1,
        notes: "Grade 50 steel",
        page_number: "3"
      )

      expect(item.item_number).to eq("ITEM-001")
      expect(item.item_description).to eq("Structural Steel - Universal Beam")
      expect(item.unit_of_measure).to eq("Tonne")
      expect(item.quantity).to eq(25.5)
      expect(item.steel_sections?).to be true
      expect(item.sequence_order).to eq(1)
      expect(item.notes).to eq("Grade 50 steel")
      expect(item.page_number).to eq("3")
    end
  end

  describe "section_category enum values" do
    let(:boq) { create(:boq) }

    it "creates blank category item" do
      item = create(:boq_item, boq: boq, section_category: "Blank")
      expect(item.blank?).to be true
    end

    it "creates steel sections item" do
      item = create(:boq_item, :steel_sections, boq: boq)
      expect(item.steel_sections?).to be true
    end

    it "creates paintwork item" do
      item = create(:boq_item, :paintwork, boq: boq)
      expect(item.paintwork?).to be true
    end

    it "creates bolts item" do
      item = create(:boq_item, :bolts, boq: boq)
      expect(item.bolts?).to be true
      expect(item.item_description).to eq("M16 Bolts")
    end

    it "creates gutter meter item" do
      item = create(:boq_item, :gutter, boq: boq)
      expect(item.gutter_meter?).to be true
    end

    it "creates mechanical anchor item" do
      item = create(:boq_item, :mechanical_anchor, boq: boq)
      expect(item.m16_mechanical_anchor?).to be true
    end

    it "creates chemical anchor item" do
      item = create(:boq_item, :chemical_anchor, boq: boq)
      expect(item.m16_chemical?).to be true
    end

    it "creates HD bolt item" do
      item = create(:boq_item, :hd_bolt, boq: boq)
      expect(item.m20_hd_bolt?).to be true
    end
  end

  describe "quantity handling" do
    let(:boq) { create(:boq) }

    it "stores quantity with 3 decimal places" do
      item = create(:boq_item, boq: boq, quantity: 10.567)
      item.reload
      expect(item.quantity).to eq(10.567)
    end

    it "defaults to 0.0 when not provided" do
      item = create(:boq_item, boq: boq, quantity: nil)
      expect(item.quantity).to be_nil
    end

    it "handles zero quantity" do
      item = create(:boq_item, boq: boq, quantity: 0.0)
      expect(item.quantity).to eq(0.0)
    end

    it "handles large quantities" do
      item = create(:boq_item, boq: boq, quantity: 9999.999)
      expect(item.quantity).to eq(9999.999)
    end
  end

  describe "sequence ordering" do
    let(:boq) { create(:boq) }

    it "maintains sequence order" do
      item1 = create(:boq_item, boq: boq, sequence_order: 1)
      item2 = create(:boq_item, boq: boq, sequence_order: 2)
      item3 = create(:boq_item, boq: boq, sequence_order: 3)

      ordered = boq.boq_items.order(:sequence_order)
      expect(ordered.pluck(:id)).to eq([item1.id, item2.id, item3.id])
    end

    it "allows duplicate sequence orders (used for grouping)" do
      item1 = create(:boq_item, boq: boq, sequence_order: 1)
      item2 = create(:boq_item, boq: boq, sequence_order: 1)

      expect(boq.boq_items.where(sequence_order: 1).count).to eq(2)
    end

    it "can be updated" do
      item = create(:boq_item, boq: boq, sequence_order: 5)
      item.update(sequence_order: 10)

      expect(item.sequence_order).to eq(10)
    end
  end

  describe "item_number handling" do
    let(:boq) { create(:boq) }

    it "stores alphanumeric item numbers" do
      item = create(:boq_item, boq: boq, item_number: "ITEM-001-A")
      expect(item.item_number).to eq("ITEM-001-A")
    end

    it "can have nil item_number" do
      item = create(:boq_item, boq: boq, item_number: nil)
      expect(item.item_number).to be_nil
    end

    it "stores item number as string" do
      item = create(:boq_item, boq: boq, item_number: "123")
      expect(item.item_number).to eq("123")
    end
  end

  describe "item_description handling" do
    let(:boq) { create(:boq) }

    it "stores long descriptions as text" do
      long_desc = "This is a very long item description " * 20
      item = create(:boq_item, boq: boq, item_description: long_desc)
      
      expect(item.item_description.length).to be > 100
      expect(item.item_description).to include("This is a very long item description")
    end

    it "can be nil" do
      item = create(:boq_item, boq: boq, item_description: nil)
      expect(item.item_description).to be_nil
    end
  end

  describe "unit_of_measure handling" do
    let(:boq) { create(:boq) }

    it "stores various units of measure" do
      units = ["Tonne", "Metre", "Box", "Piece", "Litre", "Hour", "Day"]
      
      units.each do |unit|
        item = create(:boq_item, boq: boq, unit_of_measure: unit)
        expect(item.unit_of_measure).to eq(unit)
      end
    end

    it "can be nil" do
      item = create(:boq_item, boq: boq, unit_of_measure: nil)
      expect(item.unit_of_measure).to be_nil
    end
  end

  describe "page_number handling" do
    let(:boq) { create(:boq) }

    it "stores page number as text" do
      item = create(:boq_item, boq: boq, page_number: "5-7")
      expect(item.page_number).to eq("5-7")
    end

    it "can store single page" do
      item = create(:boq_item, boq: boq, page_number: "10")
      expect(item.page_number).to eq("10")
    end

    it "can be nil" do
      item = create(:boq_item, boq: boq, page_number: nil)
      expect(item.page_number).to be_nil
    end
  end

  describe "notes handling" do
    let(:boq) { create(:boq) }

    it "stores detailed notes" do
      notes = "This item requires special handling and should be coordinated with supplier"
      item = create(:boq_item, boq: boq, notes: notes)
      
      expect(item.notes).to eq(notes)
    end

    it "can be nil" do
      item = create(:boq_item, boq: boq, notes: nil)
      expect(item.notes).to be_nil
    end
  end

  describe "timestamps" do
    let(:boq) { create(:boq) }

    it "records created_at" do
      item = create(:boq_item, boq: boq)
      expect(item.created_at).to be_present
    end

    it "records updated_at" do
      item = create(:boq_item, boq: boq)
      original_updated_at = item.updated_at

      travel 1.hour do
        item.update(item_description: "Updated description")
      end

      expect(item.updated_at).to be > original_updated_at
    end
  end

  describe "relationship with BOQ" do
    let(:boq1) { create(:boq, boq_name: "BOQ 1") }
    let(:boq2) { create(:boq, boq_name: "BOQ 2") }

    it "belongs to a specific BOQ" do
      item = create(:boq_item, boq: boq1)
      expect(item.boq).to eq(boq1)
      expect(item.boq.boq_name).to eq("BOQ 1")
    end

    it "cannot be created without a BOQ" do
      item = build(:boq_item, boq: nil)
      expect(item).not_to be_valid
      expect(item.errors[:boq_id]).to be_present
    end

    it "can be reassigned to a different BOQ" do
      item = create(:boq_item, boq: boq1)
      item.update(boq: boq2)

      expect(item.boq).to eq(boq2)
    end
  end

  describe "bulk operations" do
    let(:boq) { create(:boq) }

    it "creates multiple items for a BOQ" do
      items = create_list(:boq_item, 5, boq: boq)
      
      expect(boq.boq_items.count).to eq(5)
      expect(items.all? { |item| item.boq == boq }).to be true
    end

    it "queries items by sequence order" do
      create(:boq_item, boq: boq, sequence_order: 3)
      create(:boq_item, boq: boq, sequence_order: 1)
      create(:boq_item, boq: boq, sequence_order: 2)

      ordered = boq.boq_items.order(:sequence_order)
      expect(ordered.pluck(:sequence_order)).to eq([1, 2, 3])
    end

    it "queries items by section_category" do
      steel_item = create(:boq_item, boq: boq, section_category: "Steel Sections")
      bolt_item = create(:boq_item, boq: boq, section_category: "Bolts")

      steel_items = boq.boq_items.where(section_category: "Steel Sections")
      expect(steel_items).to include(steel_item)
      expect(steel_items).not_to include(bolt_item)
    end
  end

  describe "traits" do
    let(:boq) { create(:boq) }

    it "creates bolts item with :bolts trait" do
      item = create(:boq_item, :bolts, boq: boq)
      
      expect(item.bolts?).to be true
      expect(item.item_description).to eq("M16 Bolts")
      expect(item.unit_of_measure).to eq("Box")
      expect(item.quantity).to eq(100)
    end

    it "creates paintwork item with :paintwork trait" do
      item = create(:boq_item, :paintwork, boq: boq)
      
      expect(item.paintwork?).to be true
      expect(item.item_description).to eq("Primer Paint")
      expect(item.unit_of_measure).to eq("Litre")
    end

    it "creates mechanical anchor item with :mechanical_anchor trait" do
      item = create(:boq_item, :mechanical_anchor, boq: boq)
      
      expect(item.m16_mechanical_anchor?).to be true
      expect(item.item_description).to eq("M16 Mechanical Anchors")
    end

    it "creates chemical anchor item with :chemical_anchor trait" do
      item = create(:boq_item, :chemical_anchor, boq: boq)
      
      expect(item.m16_chemical?).to be true
      expect(item.item_description).to eq("M16 Chemical Anchors")
    end

    it "creates HD bolt item with :hd_bolt trait" do
      item = create(:boq_item, :hd_bolt, boq: boq)
      
      expect(item.m20_hd_bolt?).to be true
      expect(item.item_description).to eq("M20 HD Bolts")
    end

    it "creates gutter item with :gutter trait" do
      item = create(:boq_item, :gutter, boq: boq)
      
      expect(item.gutter_meter?).to be true
      expect(item.item_description).to eq("Gutter Meter")
      expect(item.unit_of_measure).to eq("Metre")
    end
  end
end
