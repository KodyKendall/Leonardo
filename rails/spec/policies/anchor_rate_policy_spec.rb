require 'rails_helper'

RSpec.describe AnchorRatePolicy, type: :policy do
  let(:admin) { User.create!(email: 'admin@example.com', password: 'password', role: :admin) }
  let(:material_buyer) { User.create!(email: 'buyer@example.com', password: 'password', role: :material_buyer) }
  let(:anchor_rate) { AnchorRate.create!(name: 'Test Anchor', material_cost: 10) }

  describe 'index?' do
    it 'allows access for both admin and material_buyer' do
      expect(AnchorRatePolicy.new(admin, AnchorRate).index?).to be true
      expect(AnchorRatePolicy.new(material_buyer, AnchorRate).index?).to be true
    end
  end

  describe 'create?' do
    it 'allows access for both admin and material_buyer' do
      expect(AnchorRatePolicy.new(admin, AnchorRate).create?).to be true
      expect(AnchorRatePolicy.new(material_buyer, AnchorRate).create?).to be true
    end
  end

  describe 'update?' do
    it 'allows access for both admin and material_buyer' do
      expect(AnchorRatePolicy.new(admin, anchor_rate).update?).to be true
      expect(AnchorRatePolicy.new(material_buyer, anchor_rate).update?).to be true
    end
  end

  describe 'destroy?' do
    it 'allows access for admin' do
      expect(AnchorRatePolicy.new(admin, anchor_rate).destroy?).to be true
    end

    it 'denies access for material_buyer' do
      expect(AnchorRatePolicy.new(material_buyer, anchor_rate).destroy?).to be false
    end
  end
end
