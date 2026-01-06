require 'rails_helper'

RSpec.describe CraneRatePolicy, type: :policy do
  let(:admin) { User.create!(email: 'admin_cr@example.com', password: 'password', role: :admin) }
  let(:non_admin) { User.create!(email: 'user_cr@example.com', password: 'password', role: :quantity_surveyor) }
  let(:crane_rate) { CraneRate.create!(size: '50t', ownership_type: 'rental', dry_rate_per_day: 100, diesel_per_day: 50, is_active: true, effective_from: Date.today) }

  describe 'index?' do
    it 'allows access for both admin and non-admin' do
      expect(CraneRatePolicy.new(admin, CraneRate).index?).to be true
      expect(CraneRatePolicy.new(non_admin, CraneRate).index?).to be true
    end
  end

  describe 'show?' do
    it 'allows access for both admin and non-admin' do
      expect(CraneRatePolicy.new(admin, crane_rate).show?).to be true
      expect(CraneRatePolicy.new(non_admin, crane_rate).show?).to be true
    end
  end

  describe 'create?' do
    it 'allows access for admin' do
      expect(CraneRatePolicy.new(admin, CraneRate).create?).to be true
    end

    it 'denies access for non-admin' do
      expect(CraneRatePolicy.new(non_admin, CraneRate).create?).to be false
    end
  end

  describe 'update?' do
    it 'allows access for admin' do
      expect(CraneRatePolicy.new(admin, crane_rate).update?).to be true
    end

    it 'denies access for non-admin' do
      expect(CraneRatePolicy.new(non_admin, crane_rate).update?).to be false
    end
  end

  describe 'destroy?' do
    it 'allows access for admin' do
      expect(CraneRatePolicy.new(admin, crane_rate).destroy?).to be true
    end

    it 'denies access for non-admin' do
      expect(CraneRatePolicy.new(non_admin, crane_rate).destroy?).to be false
    end
  end
end
