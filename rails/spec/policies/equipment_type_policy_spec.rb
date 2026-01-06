require 'rails_helper'

RSpec.describe EquipmentTypePolicy, type: :policy do
  let(:admin) { User.create!(email: 'admin_eq@example.com', password: 'password', role: :admin) }
  let(:non_admin) { User.create!(email: 'user_eq@example.com', password: 'password', role: :quantity_surveyor) }
  let(:equipment_type) { EquipmentType.create!(category: :diesel_boom, model: 'Model X', base_rate_monthly: 1000, damage_waiver_pct: 0.1, diesel_allowance_monthly: 500, is_active: true) }

  describe 'index?' do
    it 'allows access for both admin and non-admin' do
      expect(EquipmentTypePolicy.new(admin, EquipmentType).index?).to be true
      expect(EquipmentTypePolicy.new(non_admin, EquipmentType).index?).to be true
    end
  end

  describe 'show?' do
    it 'allows access for both admin and non-admin' do
      expect(EquipmentTypePolicy.new(admin, equipment_type).show?).to be true
      expect(EquipmentTypePolicy.new(non_admin, equipment_type).show?).to be true
    end
  end

  describe 'create?' do
    it 'allows access for admin' do
      expect(EquipmentTypePolicy.new(admin, EquipmentType).create?).to be true
    end

    it 'denies access for non-admin' do
      expect(EquipmentTypePolicy.new(non_admin, EquipmentType).create?).to be false
    end
  end

  describe 'update?' do
    it 'allows access for admin' do
      expect(EquipmentTypePolicy.new(admin, equipment_type).update?).to be true
    end

    it 'denies access for non-admin' do
      expect(EquipmentTypePolicy.new(non_admin, equipment_type).update?).to be false
    end
  end

  describe 'destroy?' do
    it 'allows access for admin' do
      expect(EquipmentTypePolicy.new(admin, equipment_type).destroy?).to be true
    end

    it 'denies access for non-admin' do
      expect(EquipmentTypePolicy.new(non_admin, equipment_type).destroy?).to be false
    end
  end
end
