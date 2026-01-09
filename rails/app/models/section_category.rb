class SectionCategory < ApplicationRecord
  has_many :section_category_templates, dependent: :destroy
  has_many :tender_line_items, dependent: :nullify
  validates :name, presence: true, uniqueness: true
  validates :display_name, presence: true

  enum supply_rates_type: {
    material_supply_rates: 'material_supply_rates',
    chemical_and_mechanical_anchor_supply_rates: 'chemical_and_mechanical_anchor_supply_rates',
    nuts_bolts_and_washer_supply_rates: 'nuts_bolts_and_washer_supply_rates'
  }

  def supply_source_model
    case supply_rates_type
    when 'material_supply_rates'
      MaterialSupply
    when 'chemical_and_mechanical_anchor_supply_rates'
      AnchorRate
    when 'nuts_bolts_and_washer_supply_rates'
      NutBoltWasherRate
    else
      MaterialSupply
    end
  end

  def self.seed_from_enums
    BoqItem.section_categories.each do |name, display_name|
      sc = find_or_initialize_by(name: name)
      sc.display_name = display_name

      case name.to_s
      when 'steel_sections', 'paintwork', 'gutter_meter'
        sc.supply_rates_type = :material_supply_rates
      when /anchor/, /chemical/
        sc.supply_rates_type = :chemical_and_mechanical_anchor_supply_rates
      when /bolt/
        sc.supply_rates_type = :nuts_bolts_and_washer_supply_rates
      end

      sc.save!
    end
  end
end
