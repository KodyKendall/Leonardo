require 'rails_helper'

RSpec.describe SectionCategory, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:tender_line_items).dependent(:nullify) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:display_name) }
    
    describe 'uniqueness' do
      subject { create(:section_category) }
      it { is_expected.to validate_uniqueness_of(:name) }
    end
  end

  describe 'enums' do
    it { is_expected.to define_enum_for(:supply_rates_type).with_values(
      material_supply_rates: 'material_supply_rates',
      chemical_and_mechanical_anchor_supply_rates: 'chemical_and_mechanical_anchor_supply_rates',
      nuts_bolts_and_washer_supply_rates: 'nuts_bolts_and_washer_supply_rates'
    ).backed_by_column_of_type(:string) }
  end
end
