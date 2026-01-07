require 'rails_helper'

RSpec.describe CraneRate, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      crane_rate = CraneRate.new(
        size: "10t",
        ownership_type: "rsb_owned",
        dry_rate_per_day: 1000,
        diesel_per_day: 500,
        effective_from: Date.today
      )
      expect(crane_rate).to be_valid
    end

    it "is invalid with an incorrect ownership_type" do
      crane_rate = CraneRate.new(ownership_type: "invalid")
      crane_rate.valid?
      expect(crane_rate.errors[:ownership_type]).to include("is not included in the list")
    end

    it "is valid with 'rental' as ownership_type" do
      crane_rate = CraneRate.new(
        size: "10t",
        ownership_type: "rental",
        dry_rate_per_day: 1000,
        diesel_per_day: 500,
        effective_from: Date.today
      )
      expect(crane_rate).to be_valid
    end

    it "is invalid if the size and ownership_type combination already exists" do
      CraneRate.create!(
        size: "50t",
        ownership_type: "rsb_owned",
        dry_rate_per_day: 1000,
        diesel_per_day: 500,
        effective_from: Date.today
      )

      duplicate = CraneRate.new(
        size: "50t",
        ownership_type: "rsb_owned",
        dry_rate_per_day: 2000,
        diesel_per_day: 600,
        effective_from: Date.today
      )

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:size]).to include("combination already exists")
    end
  end
end
