require 'rails_helper'

RSpec.describe NutBoltWasherRatePolicy, type: :policy do
  let(:admin) { User.create!(email: 'admin@example.com', password: 'password', role: :admin) }
  let(:material_buyer) { User.create!(email: 'buyer@example.com', password: 'password', role: :material_buyer) }
  let(:rate) { NutBoltWasherRate.create!(name: 'Test Nut', material_cost: 1.0) }

  describe 'index?' do
    it 'allows access for both admin and material_buyer' do
      expect(NutBoltWasherRatePolicy.new(admin, NutBoltWasherRate).index?).to be true
      expect(NutBoltWasherRatePolicy.new(material_buyer, NutBoltWasherRate).index?).to be true
    end
  end

  describe 'create?' do
    it 'allows access for both admin and material_buyer' do
      expect(NutBoltWasherRatePolicy.new(admin, NutBoltWasherRate).create?).to be true
      expect(NutBoltWasherRatePolicy.new(material_buyer, NutBoltWasherRate).create?).to be true
    end
  end

  describe 'update?' do
    it 'allows access for both admin and material_buyer' do
      expect(NutBoltWasherRatePolicy.new(admin, rate).update?).to be true
      expect(NutBoltWasherRatePolicy.new(material_buyer, rate).update?).to be true
    end
  end

  describe 'destroy?' do
    it 'allows access for admin' do
      expect(NutBoltWasherRatePolicy.new(admin, rate).destroy?).to be true
    end

    it 'denies access for material_buyer' do
      expect(NutBoltWasherRatePolicy.new(material_buyer, rate).destroy?).to be false
    end
  end
end
