class BoqItem < ApplicationRecord
  belongs_to :boq

  validates :boq_id, presence: true

  enum section_category: {
    blank: 'Blank',
    steel_sections: 'Steel Sections',
    paintwork: 'Paintwork',
    bolts: 'Bolts',
    gutter_meter: 'Gutter Meter',
    m16_mechanical_anchor: 'M16 Mechanical Anchor',
    m16_chemical: 'M16 Chemical',
    m20_chemical: 'M20 Chemical',
    m24_chemical: 'M24 Chemical',
    m16_hd_bolt: 'M16 HD Bolt',
    m20_hd_bolt: 'M20 HD Bolt',
    m24_hd_bolt: 'M24 HD Bolt',
    m30_hd_bolt: 'M30 HD Bolt',
    m36_hd_bolt: 'M36 HD Bolt',
    m42_hd_bolt: 'M42 HD Bolt'
  }

  # Returns the human-readable name for the section category
  def category_human_readable
    self.class.section_categories[section_category] || section_category
  end
end
