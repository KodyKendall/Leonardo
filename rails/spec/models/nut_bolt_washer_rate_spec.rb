require 'rails_helper'

RSpec.describe NutBoltWasherRate, type: :model do
  describe 'validations' do
    subject { NutBoltWasherRate.new(name: 'Test', waste_percentage: 7.5, material_cost: 10.0) }

    it 'is valid with valid attributes' do
      expect(subject).to be_valid
    end

    it 'is invalid without a name' do
      subject.name = nil
      expect(subject).not_to be_valid
    end

    it 'is invalid with a duplicate name' do
      NutBoltWasherRate.create!(name: 'Test', waste_percentage: 7.5, material_cost: 10.0)
      expect(subject).not_to be_valid
    end

    it 'is invalid without waste_percentage' do
      subject.waste_percentage = nil
      expect(subject).not_to be_valid
    end

    it 'is invalid with negative waste_percentage' do
      subject.waste_percentage = -1
      expect(subject).not_to be_valid
    end

    it 'is invalid without material_cost' do
      subject.material_cost = nil
      expect(subject).not_to be_valid
    end

    it 'is invalid with negative material_cost' do
      subject.material_cost = -1
      expect(subject).not_to be_valid
    end

    it 'allows calculation_breakdown and mass_per_each to be set' do
      subject.calculation_breakdown = 'Testing 123'
      subject.mass_per_each = 0.5
      expect(subject).to be_valid
      expect(subject.calculation_breakdown).to eq('Testing 123')
      expect(subject.mass_per_each).to eq(0.5)
    end

    it 'is valid if calculation_breakdown and mass_per_each are blank' do
      subject.calculation_breakdown = nil
      subject.mass_per_each = nil
      expect(subject).to be_valid
    end
  end
end
