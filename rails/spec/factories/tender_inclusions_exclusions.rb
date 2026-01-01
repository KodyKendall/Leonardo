FactoryBot.define do
  factory :tender_inclusions_exclusion do
    tender
    fabrication_included { true }
    overheads_included { true }
    primer_included { false }
    final_paint_included { false }
    delivery_included { true }
    bolts_included { true }
    erection_included { true }
    crainage_included { false }
    cherry_pickers_included { true }
    steel_galvanized { false }
  end
end
