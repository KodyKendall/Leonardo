require 'rails_helper'

RSpec.describe RateBuildupCustomItem, type: :model do
  describe "validations" do
    let(:tender) { create(:tender) }
    let(:line_item) { create(:tender_line_item, tender: tender) }
    let(:rate_buildup) { line_item.line_item_rate_build_up }
    let(:custom_item) { rate_buildup.rate_buildup_custom_items.build(description: "Test Item", rate: 50.0) }

    it "accepts included value of 100.50 (large value)" do
      custom_item.included = 100.50
      expect(custom_item).to be_valid
    end

    it "accepts included value of 1000.00" do
      custom_item.included = 1000.00
      expect(custom_item).to be_valid
    end

    it "accepts included value of 0.01 (minimum boundary)" do
      custom_item.included = 0.01
      expect(custom_item).to be_valid
    end

    it "rejects included value of 0.00 (below minimum)" do
      custom_item.included = 0.00
      expect(custom_item).not_to be_valid
      expect(custom_item.errors[:included]).to include("must be greater than or equal to 0.01")
    end

    it "rejects included value of 0.001 (below minimum)" do
      custom_item.included = 0.001
      expect(custom_item).not_to be_valid
    end

    it "rejects nil included value" do
      custom_item.included = nil
      expect(custom_item).not_to be_valid
      expect(custom_item.errors[:included]).to include("can't be blank")
    end

    it "requires description" do
      custom_item.description = nil
      expect(custom_item).not_to be_valid
      expect(custom_item.errors[:description]).to include("can't be blank")
    end

    it "validates description length maximum of 255 characters" do
      custom_item.description = "a" * 256
      expect(custom_item).not_to be_valid
      expect(custom_item.errors[:description]).to include("is too long (maximum is 255 characters)")
    end

    it "requires rate" do
      custom_item.rate = nil
      expect(custom_item).not_to be_valid
      expect(custom_item.errors[:rate]).to include("can't be blank")
    end

    it "accepts rate value of 0" do
      custom_item.rate = 0
      expect(custom_item).to be_valid
    end
  end

  describe "amount calculation" do
    let(:tender) { create(:tender) }
    let(:line_item) { create(:tender_line_item, tender: tender) }
    let(:rate_buildup) { line_item.line_item_rate_build_up }
    let(:custom_item) { rate_buildup.rate_buildup_custom_items.build(description: "Test Item") }

    it "calculates amount as rate × included" do
      custom_item.update!(rate: 50.0, included: 100.0)
      expect(custom_item.amount).to eq(5000.0)
    end

    it "handles large multiplier values correctly" do
      custom_item.update!(rate: 100.0, included: 500.50)
      expect(custom_item.amount).to eq(50050.0)
    end

    it "returns 0 when rate is 0" do
      custom_item.update!(rate: 0, included: 100.0)
      expect(custom_item.amount).to eq(0.0)
    end

    it "uses 1.0 as default for included when nil in amount calculation" do
      # Built with no included value, testing the amount method's fallback
      item = RateBuildupCustomItem.new(description: "Test", rate: 50.0)
      expect(item.amount).to eq(50.0)
    end

    it "handles decimal rate values" do
      custom_item.update!(rate: 12.50, included: 10.0)
      expect(custom_item.amount).to eq(125.0)
    end
  end

  describe "persistence" do
    let(:tender) { create(:tender) }
    let(:line_item) { create(:tender_line_item, tender: tender) }
    let(:rate_buildup) { line_item.line_item_rate_build_up }

    it "saves and retrieves included value of 100.00" do
      custom_item = rate_buildup.rate_buildup_custom_items.create!(
        description: "Test Item",
        rate: 50.0,
        included: 100.00
      )
      
      reloaded = RateBuildupCustomItem.find(custom_item.id)
      expect(reloaded.included).to eq(100.00)
    end

    it "saves and retrieves large included value like 999.99" do
      custom_item = rate_buildup.rate_buildup_custom_items.create!(
        description: "Large Multiplier Item",
        rate: 25.0,
        included: 999.99
      )
      
      reloaded = RateBuildupCustomItem.find(custom_item.id)
      expect(reloaded.included).to eq(999.99)
      expect(reloaded.amount).to eq(24999.75)
    end
  end
end
