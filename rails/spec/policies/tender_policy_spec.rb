require 'rails_helper'

RSpec.describe TenderPolicy, type: :policy do
  let(:admin) { User.create!(email: 'admin@example.com', password: 'password', role: :admin) }
  let(:qs) { User.create!(email: 'qs@example.com', password: 'password', role: :quantity_surveyor) }
  let(:material_buyer) { User.create!(email: 'buyer@example.com', password: 'password', role: :material_buyer) }
  let(:tender) { Tender.create!(tender_name: 'Test Tender', status: 'Draft') }

  describe 'index?' do
    it 'allows access for admin and qs' do
      expect(TenderPolicy.new(admin, Tender).index?).to be true
      expect(TenderPolicy.new(qs, Tender).index?).to be true
    end

    it 'denies access for material_buyer' do
      expect(TenderPolicy.new(material_buyer, Tender).index?).to be false
    end
  end

  describe 'show?' do
    it 'allows access for admin and qs' do
      expect(TenderPolicy.new(admin, tender).show?).to be true
      expect(TenderPolicy.new(qs, tender).show?).to be true
    end

    it 'denies access for material_buyer' do
      expect(TenderPolicy.new(material_buyer, tender).show?).to be false
    end
  end
end
