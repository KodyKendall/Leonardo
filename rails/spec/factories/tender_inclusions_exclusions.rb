FactoryBot.define do
  factory :tender_inclusions_exclusion do
    tender { nil }
    fabrication_included { false }
    overheads_included { false }
    primer_included { false }
    final_paint_included { false }
    delivery_included { false }
    bolts_included { false }
    erection_included { false }
    crainage_included { false }
    cherry_pickers_included { false }
    steel_galvanized { false }
  end
end
