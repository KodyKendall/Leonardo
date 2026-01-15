require 'rails_helper'

RSpec.describe MonthlyMaterialSupplyRatePolicy, type: :policy do
  let(:admin) { User.create!(email: 'admin@example.com', password: 'password', role: :admin) }
  let(:non_admin) { User.create!(email: 'user@example.com', password: 'password', role: :quantity_surveyor) }
  let(:material_buyer) { User.create!(email: 'buyer@example.com', password: 'password', role: :material_buyer) }
  let(:monthly_rate) { MonthlyMaterialSupplyRate.create!(effective_from: Date.today.beginning_of_month, effective_to: Date.today.end_of_month) }

  describe 'index?' do
    it 'allows access for admin, non-admin and material_buyer' do
      expect(MonthlyMaterialSupplyRatePolicy.new(admin, MonthlyMaterialSupplyRate).index?).to be true
      expect(MonthlyMaterialSupplyRatePolicy.new(non_admin, MonthlyMaterialSupplyRate).index?).to be true
      expect(MonthlyMaterialSupplyRatePolicy.new(material_buyer, MonthlyMaterialSupplyRate).index?).to be true
    end
  end

  describe 'show?' do
    it 'allows access for admin, non-admin and material_buyer' do
      expect(MonthlyMaterialSupplyRatePolicy.new(admin, monthly_rate).show?).to be true
      expect(MonthlyMaterialSupplyRatePolicy.new(non_admin, monthly_rate).show?).to be true
      expect(MonthlyMaterialSupplyRatePolicy.new(material_buyer, monthly_rate).show?).to be true
    end
  end

  describe 'create?' do
    it 'allows access for admin' do
      expect(MonthlyMaterialSupplyRatePolicy.new(admin, MonthlyMaterialSupplyRate).create?).to be true
    end

    it 'allows access for material_buyer' do
      expect(MonthlyMaterialSupplyRatePolicy.new(material_buyer, MonthlyMaterialSupplyRate).create?).to be true
    end

    it 'denies access for non-admin' do
      expect(MonthlyMaterialSupplyRatePolicy.new(non_admin, MonthlyMaterialSupplyRate).create?).to be false
    end
  end

  describe 'update?' do
    it 'allows access for admin' do
      expect(MonthlyMaterialSupplyRatePolicy.new(admin, monthly_rate).update?).to be true
    end

    it 'allows access for material_buyer' do
      expect(MonthlyMaterialSupplyRatePolicy.new(material_buyer, monthly_rate).update?).to be true
    end

    it 'denies access for non-admin' do
      expect(MonthlyMaterialSupplyRatePolicy.new(non_admin, monthly_rate).update?).to be false
    end
  end

  describe 'destroy?' do
    it 'allows access for admin' do
      expect(MonthlyMaterialSupplyRatePolicy.new(admin, monthly_rate).destroy?).to be true
    end

    it 'denies access for non-admin' do
      expect(MonthlyMaterialSupplyRatePolicy.new(non_admin, monthly_rate).destroy?).to be false
    end

    it 'denies access for material_buyer' do
      expect(MonthlyMaterialSupplyRatePolicy.new(material_buyer, monthly_rate).destroy?).to be false
    end
  end

  describe 'save_rate?' do
    it 'allows access for admin' do
      expect(MonthlyMaterialSupplyRatePolicy.new(admin, monthly_rate).save_rate?).to be true
    end

    it 'allows access for material_buyer' do
      expect(MonthlyMaterialSupplyRatePolicy.new(material_buyer, monthly_rate).save_rate?).to be true
    end

    it 'denies access for non-admin' do
      expect(MonthlyMaterialSupplyRatePolicy.new(non_admin, monthly_rate).save_rate?).to be false
    end
  end

  describe 'set_2nd_cheapest_as_winners?' do
    it 'allows access for admin' do
      expect(MonthlyMaterialSupplyRatePolicy.new(admin, monthly_rate).set_2nd_cheapest_as_winners?).to be true
    end

    it 'allows access for material_buyer' do
      expect(MonthlyMaterialSupplyRatePolicy.new(material_buyer, monthly_rate).set_2nd_cheapest_as_winners?).to be true
    end

    it 'denies access for non-admin' do
      expect(MonthlyMaterialSupplyRatePolicy.new(non_admin, monthly_rate).set_2nd_cheapest_as_winners?).to be false
    end
  end
end
