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
end
