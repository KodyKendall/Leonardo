require 'rails_helper'

RSpec.describe SectionCategoryPolicy, type: :policy do
  let(:admin) { User.create!(email: 'admin@example.com', password: 'password', role: :admin) }
  let(:non_admin) { User.create!(email: 'user@example.com', password: 'password', role: :quantity_surveyor) }
  let(:section_category) { SectionCategory.create!(name: 'Test Category', display_name: 'Test Category') }

  describe 'index?' do
    it 'allows access for both admin and non-admin' do
      expect(SectionCategoryPolicy.new(admin, SectionCategory).index?).to be true
      expect(SectionCategoryPolicy.new(non_admin, SectionCategory).index?).to be true
    end
  end

  describe 'show?' do
    it 'allows access for both admin and non-admin' do
      expect(SectionCategoryPolicy.new(admin, section_category).show?).to be true
      expect(SectionCategoryPolicy.new(non_admin, section_category).show?).to be true
    end
  end

  describe 'create?' do
    it 'allows access for admin' do
      expect(SectionCategoryPolicy.new(admin, SectionCategory).create?).to be true
    end

    it 'denies access for non-admin' do
      expect(SectionCategoryPolicy.new(non_admin, SectionCategory).create?).to be false
    end
  end

  describe 'update?' do
    it 'allows access for admin' do
      expect(SectionCategoryPolicy.new(admin, section_category).update?).to be true
    end

    it 'denies access for non-admin' do
      expect(SectionCategoryPolicy.new(non_admin, section_category).update?).to be false
    end
  end

  describe 'destroy?' do
    it 'allows access for admin' do
      expect(SectionCategoryPolicy.new(admin, section_category).destroy?).to be true
    end

    it 'denies access for non-admin' do
      expect(SectionCategoryPolicy.new(non_admin, section_category).destroy?).to be false
    end
  end
end
