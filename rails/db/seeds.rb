# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#

# ===== SECTION CATEGORIES =====
SectionCategory.seed_from_enums

# ===== USERS =====
admin_user = User.find_or_create_by!(email: 'kody@llamapress.ai') do |user|
  user.name = 'Kody Admin'
  user.password = '123456'
  user.password_confirmation = '123456'
  user.role = 'admin'
  user.admin = true
end

rich = User.find_or_create_by!(email: 'rspencer@rsbcontracts.com') do |user|
  user.name = 'Rich Spencer'
  user.password = 'Rich456'
  user.password_confirmation = 'Rich456'
  user.role = 'admin'
  user.admin = true
end

demi = User.find_or_create_by!(email: 'demi@rsbcontracts.com') do |user|
  user.name = 'Demi'
  user.password = 'Demi456'
  user.password_confirmation = 'Demi456'
  user.role = 'quantity_surveyor'
end

elmari = User.find_or_create_by!(email: 'elmari@rsbcontracts.com') do |user|
  user.name = 'Elmari'
  user.password = 'Elmari456'
  user.password_confirmation = 'Elmari456'
  user.role = 'office'
end

# ===== BUDGET CATEGORIES =====
budget_cats = [
  { category_name: 'Labor', cost_code: 'LB001', description: 'Direct labor costs for project staff' },
  { category_name: 'Materials', cost_code: 'MT001', description: 'Raw materials and supplies' },
  { category_name: 'Equipment', cost_code: 'EQ001', description: 'Equipment rental and purchase' },
  { category_name: 'Subcontractors', cost_code: 'SC001', description: 'Third-party contractor services' },
  { category_name: 'Contingency', cost_code: 'CT001', description: 'Contingency and reserve funds' },
  { category_name: 'Travel', cost_code: 'TV001', description: 'Travel and accommodation costs' }
]

budget_categories = budget_cats.map do |attrs|
  BudgetCategory.find_or_create_by!(category_name: attrs[:category_name]) do |cat|
    cat.cost_code = attrs[:cost_code]
    cat.description = attrs[:description]
  end
end

# ===== TENDERS (create first) =====
tender1 = Tender.find_or_create_by!(e_number: 'E-2024-001') do |t|
  t.tender_name = 'ABC High-Rise'
  t.status = 'Draft'
  t.client_name = 'ABC Construction Ltd'
  t.tender_value = 500000.00
  t.project_type = 'Commercial'
  t.notes = 'High-rise commercial building project'
end

tender2 = Tender.find_or_create_by!(e_number: 'E-2024-002') do |t|
  t.tender_name = 'XYZ Mining Operation'
  t.status = 'Draft'
  t.client_name = 'XYZ Infrastructure'
  t.tender_value = 1200000.00
  t.project_type = 'Mining'
  t.notes = 'Steel fabrication for mining complex'
end

tender3 = Tender.find_or_create_by!(e_number: 'E-2024-003') do |t|
  t.tender_name = 'Smart City Office Complex'
  t.status = 'Draft'
  t.client_name = 'Smart City Developers'
  t.tender_value = 350000.00
  t.project_type = 'Commercial'
  t.notes = 'Office complex in downtown area'
end

tender4 = Tender.find_or_create_by!(e_number: 'E-2024-004') do |t|
  t.tender_name = 'Heritage Renovations'
  t.status = 'Draft'
  t.client_name = 'Heritage Renovations Inc'
  t.tender_value = 180000.00
  t.project_type = 'Commercial'
end

# ===== PROJECTS (now create with tenders and users) =====
project1 = Project.find_or_create_by!(rsb_number: 'RSB-2024-001') do |p|
  p.tender = tender1
  p.project_status = 'active'
  p.project_start_date = Date.new(2024, 1, 15)
  p.project_end_date = Date.new(2024, 12, 31)
  p.budget_total = 500000.00
  p.actual_spend = 250000.00
  p.created_by = rich
end

project2 = Project.find_or_create_by!(rsb_number: 'RSB-2024-002') do |p|
  p.tender = tender2
  p.project_status = 'active'
  p.project_start_date = Date.new(2024, 3, 1)
  p.project_end_date = Date.new(2025, 2, 28)
  p.budget_total = 1200000.00
  p.actual_spend = 450000.00
  p.created_by = rich
end

project3 = Project.find_or_create_by!(rsb_number: 'RSB-2024-003') do |p|
  p.tender = tender4
  p.project_status = 'planning'
  p.project_start_date = Date.new(2024, 6, 1)
  p.project_end_date = Date.new(2024, 9, 30)
  p.budget_total = 180000.00
  p.actual_spend = 0.00
  p.created_by = rich
end

# Update tenders with their awarded projects
tender1.update(awarded_project: project1)
tender2.update(awarded_project: project2)
tender4.update(awarded_project: project3)

# ===== BUDGET ALLOWANCES =====
project1.budget_allowances.find_or_create_by!(budget_category: budget_categories[0]) do |ba|
  ba.budgeted_amount = 150000.00
  ba.actual_spend = 120000.00
  ba.variance = -30000.00
end

project1.budget_allowances.find_or_create_by!(budget_category: budget_categories[1]) do |ba|
  ba.budgeted_amount = 200000.00
  ba.actual_spend = 95000.00
  ba.variance = -105000.00
end

project1.budget_allowances.find_or_create_by!(budget_category: budget_categories[4]) do |ba|
  ba.budgeted_amount = 150000.00
  ba.actual_spend = 35000.00
  ba.variance = -115000.00
end

project2.budget_allowances.find_or_create_by!(budget_category: budget_categories[1]) do |ba|
  ba.budgeted_amount = 600000.00
  ba.actual_spend = 300000.00
  ba.variance = -300000.00
end

project2.budget_allowances.find_or_create_by!(budget_category: budget_categories[2]) do |ba|
  ba.budgeted_amount = 400000.00
  ba.actual_spend = 120000.00
  ba.variance = -280000.00
end

project2.budget_allowances.find_or_create_by!(budget_category: budget_categories[3]) do |ba|
  ba.budgeted_amount = 200000.00
  ba.actual_spend = 30000.00
  ba.variance = -170000.00
end

# ===== FABRICATION RECORDS =====
FabricationRecord.find_or_create_by!(project: project2, record_month: Date.new(2024, 3, 1)) do |fr|
  fr.tonnes_fabricated = 45.500
  fr.allowed_rate = 5000.00
  fr.allowed_amount = 227500.00
  fr.actual_spend = 215000.00
end

FabricationRecord.find_or_create_by!(project: project2, record_month: Date.new(2024, 4, 1)) do |fr|
  fr.tonnes_fabricated = 38.200
  fr.allowed_rate = 5000.00
  fr.allowed_amount = 191000.00
  fr.actual_spend = 188500.00
end

FabricationRecord.find_or_create_by!(project: project2, record_month: Date.new(2024, 5, 1)) do |fr|
  fr.tonnes_fabricated = 52.750
  fr.allowed_rate = 5000.00
  fr.allowed_amount = 263750.00
  fr.actual_spend = 258000.00
end

# ===== VARIATION ORDERS =====
vo1 = VariationOrder.find_or_create_by!(vo_number: 'VO-2024-001') do |vo|
  vo.project = project1
  vo.vo_status = 'approved'
  vo.vo_amount = 25000.00
  vo.description = 'Additional structural reinforcement required by client'
  vo.created_by = rich
  vo.approved_by = rich
  vo.approver_notes = 'Approved. Client acceptance required before work commences.'
  vo.approved_at = 5.days.ago
end

vo2 = VariationOrder.find_or_create_by!(vo_number: 'VO-2024-002') do |vo|
  vo.project = project1
  vo.vo_status = 'pending'
  vo.vo_amount = 15000.00
  vo.description = 'Expedited delivery of materials'
  vo.created_by = rich
end

vo3 = VariationOrder.find_or_create_by!(vo_number: 'VO-2024-003') do |vo|
  vo.project = project2
  vo.vo_status = 'approved'
  vo.vo_amount = 45000.00
  vo.description = 'Additional fabrication capacity for accelerated timeline'
  vo.created_by = rich
  vo.approved_by = rich
  vo.approver_notes = 'Approved with condition that schedule is maintained.'
  vo.approved_at = 10.days.ago
end

# ===== CLAIMS =====
claim1 = Claim.find_or_create_by!(claim_number: 'CLM-2024-001') do |c|
  c.project = project1
  c.claim_date = Date.new(2024, 4, 30)
  c.claim_status = 'submitted'
  c.total_claimed = 85000.00
  c.total_paid = 0.00
  c.amount_due = 85000.00
  c.submitted_by = rich
  c.notes = 'First progress claim for works completed in April'
end

claim2 = Claim.find_or_create_by!(claim_number: 'CLM-2024-002') do |c|
  c.project = project1
  c.claim_date = Date.new(2024, 5, 31)
  c.claim_status = 'paid'
  c.total_claimed = 95000.00
  c.total_paid = 95000.00
  c.amount_due = 0.00
  c.submitted_by = rich
  c.notes = 'Second progress claim for works completed in May'
end

claim3 = Claim.find_or_create_by!(claim_number: 'CLM-2024-003') do |c|
  c.project = project2
  c.claim_date = Date.new(2024, 4, 15)
  c.claim_status = 'submitted'
  c.total_claimed = 150000.00
  c.total_paid = 0.00
  c.amount_due = 150000.00
  c.submitted_by = rich
  c.notes = 'First progress claim for fabrication works'
end

# ===== CLAIM LINE ITEMS =====
ClaimLineItem.find_or_create_by!(claim: claim1, line_item_description: 'Steel structural framework - Phase 1') do |cli|
  cli.tender_rate = 500.00
  cli.claimed_quantity = 80.000
  cli.claimed_amount = 40000.00
  cli.cumulative_quantity = 80.000
  cli.is_new_item = false
  cli.price_escalation = 0.00
end

ClaimLineItem.find_or_create_by!(claim: claim1, line_item_description: 'Labor - Site installation') do |cli|
  cli.tender_rate = 45.00
  cli.claimed_quantity = 1000.000
  cli.claimed_amount = 45000.00
  cli.cumulative_quantity = 1000.000
  cli.is_new_item = false
  cli.price_escalation = 0.00
end

ClaimLineItem.find_or_create_by!(claim: claim2, line_item_description: 'Steel structural framework - Phase 2') do |cli|
  cli.tender_rate = 520.00
  cli.claimed_quantity = 75.000
  cli.claimed_amount = 39000.00
  cli.cumulative_quantity = 155.000
  cli.is_new_item = false
  cli.price_escalation = 20.00
end

ClaimLineItem.find_or_create_by!(claim: claim2, line_item_description: 'Labor - Site installation Phase 2') do |cli|
  cli.tender_rate = 48.00
  cli.claimed_quantity = 1200.000
  cli.claimed_amount = 56000.00
  cli.cumulative_quantity = 2200.000
  cli.is_new_item = false
  cli.price_escalation = 3.00
end

ClaimLineItem.find_or_create_by!(claim: claim3, line_item_description: 'Fabrication - Beams and Columns') do |cli|
  cli.tender_rate = 4500.00
  cli.claimed_quantity = 25.500
  cli.claimed_amount = 114750.00
  cli.cumulative_quantity = 25.500
  cli.is_new_item = false
  cli.price_escalation = 0.00
end

ClaimLineItem.find_or_create_by!(claim: claim3, line_item_description: 'Welding and connections') do |cli|
  cli.tender_rate = 1200.00
  cli.claimed_quantity = 30.000
  cli.claimed_amount = 36000.00
  cli.cumulative_quantity = 30.000
  cli.is_new_item = false
  cli.price_escalation = 0.00
end

# ===== SUPPLIERS =====
suppliers_data = [
  'BSI',
  'MacSteel',
  'Steelrode',
  'S&L',
  'BBD',
  'Fast Flame'
]

suppliers = suppliers_data.map do |name|
  Supplier.find_or_create_by!(name: name)
end

# ===== MATERIAL SUPPLIES =====
material_supplies_data = [
  { name: 'UnEqual Angles', waste_percentage: 7.50 },
  { name: 'Equal Angles', waste_percentage: 7.50 },
  { name: 'Large Equal Angles', waste_percentage: 7.50 },
  { name: 'Local UB & UC Sections', waste_percentage: 7.50 },
  { name: 'Import UB & UC Sections', waste_percentage: 7.50 },
  { name: 'PFC Sections', waste_percentage: 7.50 },
  { name: 'Heavy PFC Sections', waste_percentage: 7.50 },
  { name: 'IPE Sections', waste_percentage: 7.50 },
  { name: 'Sheets of Plate Decoil up to 12mm', waste_percentage: 12.50 },
  { name: 'Sheets of Plate As Rolled 16mm & up', waste_percentage: 12.50 },
  { name: 'Cut to Size Plate', waste_percentage: 0.00 },
  { name: 'Standard Hollow Sections', waste_percentage: 12.50 },
  { name: 'Non-Standard Hollow Sections', waste_percentage: 10.00 },
  { name: 'Gutters', waste_percentage: 0.00 },
  { name: 'Round Bar', waste_percentage: 10.00 },
  { name: 'CFLC - Black', waste_percentage: 0.00 },
  { name: 'CFLC - Primed', waste_percentage: 0.00 },
  { name: 'CFLC - Pregalv', waste_percentage: 0.00 },
  { name: 'CFLC Metsec Alternative 1.6mm', waste_percentage: 0.00 },
  { name: 'CFLC Metsec Alternative 2mm', waste_percentage: 0.00 },
  { name: 'CFLC - Black 100mm Leg', waste_percentage: 0.00 },
  { name: 'CFLC - Primed 100mm Leg', waste_percentage: 0.00 },
  { name: 'CFLC - Pregalv 100mm Leg', waste_percentage: 0.00 }
]

material_supplies = material_supplies_data.map.with_index do |attrs, index|
  ms = MaterialSupply.find_by(name: attrs[:name])
  
  # Special case for the split item if it doesn't exist yet but "Sheets of Plate" does
  if attrs[:name] == 'Sheets of Plate Decoil up to 12mm' && !ms
    old_item = MaterialSupply.find_by(name: 'Sheets of Plate')
    if old_item
      old_item.update!(name: attrs[:name])
      ms = old_item
    end
  end

  ms ||= MaterialSupply.find_or_create_by!(name: attrs[:name]) do |m|
    m.waste_percentage = attrs[:waste_percentage]
    m.position = index + 1
  end

  # Always update to ensure correct state
  ms.update!(waste_percentage: attrs[:waste_percentage], position: index + 1)
  ms
end

# ===== TENDER LINE ITEMS (for testing the builder) =====
line_item_1 = tender3.tender_line_items.find_or_create_by!(
  item_number: 'LI-001',
  item_description: 'Light Structural Steel - Up to 25 kg/m',
  unit_of_measure: 'tonne',
  quantity: 45.5,
  rate: 15500.00,
  section_category: SectionCategory.find_by(display_name: 'Steel Sections'),
  page_number: '1',
  notes: 'Supplied and erected on site'
) do |li|
  li.section_category = SectionCategory.find_by(display_name: 'Steel Sections')
end

line_item_2 = tender3.tender_line_items.find_or_create_by!(
  item_number: 'LI-002',
  item_description: 'Heavy Structural Steel - Over 25 kg/m',
  unit_of_measure: 'tonne',
  quantity: 28.3,
  rate: 16800.00,
  section_category: SectionCategory.find_by(display_name: 'Steel Sections'),
  page_number: '1',
  notes: 'Supplied and erected on site'
) do |li|
  li.section_category = SectionCategory.find_by(display_name: 'Steel Sections')
end

line_item_3 = tender3.tender_line_items.find_or_create_by!(
  item_number: 'LI-003',
  item_description: 'Bolts and Fasteners',
  unit_of_measure: 'kg',
  quantity: 500,
  rate: 85.00,
  section_category: SectionCategory.find_by(display_name: 'Bolts'),
  page_number: '2',
  notes: 'M16, M20, M24 HD Bolts'
) do |li|
  li.section_category = SectionCategory.find_by(display_name: 'Bolts')
end

# ===== LINE ITEM RATE BUILD-UPS =====
# For line_item_1
rate_buildup_1 = line_item_1.line_item_rate_build_up || line_item_1.create_line_item_rate_build_up
rate_buildup_1.update(
  material_supply_rate: 8500.00,
  material_supply_included: true,
  fabrication_rate: 4200.00,
  fabrication_included: true,
  overheads_rate: 1800.00,
  overheads_included: true,
  delivery_rate: 500.00,
  delivery_included: true,
  bolts_rate: 200.00,
  bolts_included: true,
  erection_rate: 300.00,
  erection_included: true
)

# For line_item_2
rate_buildup_2 = line_item_2.line_item_rate_build_up || line_item_2.create_line_item_rate_build_up
rate_buildup_2.update(
  material_supply_rate: 9500.00,
  material_supply_included: true,
  fabrication_rate: 4800.00,
  fabrication_included: true,
  overheads_rate: 1800.00,
  overheads_included: true,
  shop_priming_rate: 400.00,
  shop_priming_included: false,
  delivery_rate: 500.00,
  delivery_included: true
)

# For line_item_3
rate_buildup_3 = line_item_3.line_item_rate_build_up || line_item_3.create_line_item_rate_build_up
rate_buildup_3.update(
  material_supply_rate: 45.00,
  material_supply_included: true,
  delivery_rate: 15.00,
  delivery_included: true,
  bolts_rate: 25.00,
  bolts_included: true
)

# ===== LINE ITEM MATERIAL BREAKDOWNS =====
# For line_item_1
breakdown_1 = line_item_1.line_item_material_breakdown || line_item_1.create_line_item_material_breakdown
breakdown_1.save

# Add materials to breakdown_1
LineItemMaterial.find_or_create_by!(
  line_item_material_breakdown_id: breakdown_1.id,
  tender_line_item_id: line_item_1.id,
  material_supply_id: material_supplies[3].id
) do |m|
  m.waste_percentage = 7.50
  m.rate = 8200.00
  m.quantity = 30.0
  m.proportion_percentage = 65.0
end

LineItemMaterial.find_or_create_by!(
  line_item_material_breakdown_id: breakdown_1.id,
  tender_line_item_id: line_item_1.id,
  material_supply_id: material_supplies[4].id
) do |m|
  m.waste_percentage = 7.50
  m.rate = 8800.00
  m.quantity = 15.5
  m.proportion_percentage = 35.0
end

# For line_item_2
breakdown_2 = line_item_2.line_item_material_breakdown || line_item_2.create_line_item_material_breakdown
breakdown_2.save

LineItemMaterial.find_or_create_by!(
  line_item_material_breakdown_id: breakdown_2.id,
  tender_line_item_id: line_item_2.id,
  material_supply_id: material_supplies[3].id
) do |m|
  m.waste_percentage = 7.50
  m.rate = 9200.00
  m.quantity = 28.3
  m.proportion_percentage = 100.0
end

# For line_item_3
breakdown_3 = line_item_3.line_item_material_breakdown || line_item_3.create_line_item_material_breakdown
breakdown_3.save

LineItemMaterial.find_or_create_by!(
  line_item_material_breakdown_id: breakdown_3.id,
  tender_line_item_id: line_item_3.id,
  material_supply_id: material_supplies[0].id
) do |m|
  m.waste_percentage = 0.0
  m.rate = 42.00
  m.quantity = 500
  m.proportion_percentage = 100.0
end

# ===== CRANE RATES =====
crane_rates_data = [
  { size: '110t', ownership_type: 'rental', dry_rate_per_day: 12500.00, diesel_per_day: 1000.00 },
  { size: '90t', ownership_type: 'rental', dry_rate_per_day: 12500.00, diesel_per_day: 1000.00 },
  { size: '50t', ownership_type: 'rental', dry_rate_per_day: 8500.00, diesel_per_day: 850.00 },
  { size: '35t', ownership_type: 'rental', dry_rate_per_day: 3850.00, diesel_per_day: 750.00 },
  { size: '30t', ownership_type: 'rental', dry_rate_per_day: 3650.00, diesel_per_day: 750.00 },
  { size: '25t', ownership_type: 'rental', dry_rate_per_day: 3400.00, diesel_per_day: 750.00 },
  { size: '20t', ownership_type: 'rsb_owned', dry_rate_per_day: 3150.00, diesel_per_day: 750.00 },
  { size: '10t', ownership_type: 'rental', dry_rate_per_day: 1300.00, diesel_per_day: 750.00 },
  { size: '10t', ownership_type: 'rsb_owned', dry_rate_per_day: 2050.00, diesel_per_day: 750.00 }
]

crane_rates_data.each do |attrs|
  CraneRate.find_or_create_by!(size: attrs[:size], ownership_type: attrs[:ownership_type]) do |cr|
    cr.effective_from = Date.new(2025, 1, 1)
    cr.dry_rate_per_day = attrs[:dry_rate_per_day]
    cr.diesel_per_day = attrs[:diesel_per_day]
    cr.is_active = true
  end
end

# ===== CRANE COMPLEMENTS =====
crane_complements_data = [
  { area_min_sqm: 0.00, area_max_sqm: 150.00, crane_recommendation: '1 × 25t', default_wet_rate_per_day: 1.00 },
  { area_min_sqm: 150.00, area_max_sqm: 250.00, crane_recommendation: '2 × 25t', default_wet_rate_per_day: 2.00 },
  { area_min_sqm: 250.00, area_max_sqm: 350.00, crane_recommendation: '3 × 10t', default_wet_rate_per_day: 3.00 },
  { area_min_sqm: 350.00, area_max_sqm: 450.00, crane_recommendation: '2 × 10t + 1 × 25t + 2 × 35t', default_wet_rate_per_day: 4.00 },
  { area_min_sqm: 450.00, area_max_sqm: 550.00, crane_recommendation: '2 × 10t + 2 × 25t + 2 × 35t + 1 × 50t', default_wet_rate_per_day: 5.00 }
]

crane_complements_data.each do |attrs|
  CraneComplement.find_or_create_by!(
    area_min_sqm: attrs[:area_min_sqm],
    area_max_sqm: attrs[:area_max_sqm]
  ) do |cc|
    cc.crane_recommendation = attrs[:crane_recommendation]
    cc.default_wet_rate_per_day = attrs[:default_wet_rate_per_day]
  end
end

# ===== ON-SITE MOBILE CRANE BREAKDOWNS =====
OnSiteMobileCraneBreakdown.find_or_create_by!(tender: tender1) do |breakdown|
  breakdown.total_roof_area_sqm = 2500.00
  breakdown.erection_rate_sqm_per_day = 150.00
  breakdown.ownership_type = 'rental'
  breakdown.splicing_crane_required = true
  breakdown.splicing_crane_size = '25t'
  breakdown.splicing_crane_days = 14
  breakdown.misc_crane_required = true
  breakdown.misc_crane_size = '10t'
  breakdown.misc_crane_days = 7
end

OnSiteMobileCraneBreakdown.find_or_create_by!(tender: tender2) do |breakdown|
  breakdown.total_roof_area_sqm = 5000.00
  breakdown.erection_rate_sqm_per_day = 200.00
  breakdown.ownership_type = 'rsb_owned'
  breakdown.splicing_crane_required = true
  breakdown.splicing_crane_size = '35t'
  breakdown.splicing_crane_days = 21
  breakdown.misc_crane_required = false
end

OnSiteMobileCraneBreakdown.find_or_create_by!(tender: tender3) do |breakdown|
  breakdown.total_roof_area_sqm = 1800.00
  breakdown.erection_rate_sqm_per_day = 120.00
  breakdown.ownership_type = 'rental'
  breakdown.splicing_crane_required = false
  breakdown.misc_crane_required = true
  breakdown.misc_crane_size = '20t'
  breakdown.misc_crane_days = 5
end

OnSiteMobileCraneBreakdown.find_or_create_by!(tender: tender4) do |breakdown|
  breakdown.total_roof_area_sqm = 1200.00
  breakdown.erection_rate_sqm_per_day = 100.00
  breakdown.ownership_type = 'rental'
  breakdown.splicing_crane_required = false
  breakdown.misc_crane_required = false
end

# ===== BOQS (BILLS OF QUANTITIES) =====
boq1 = Boq.find_or_create_by!(boq_name: 'ABC High-Rise - BOQ', file_name: 'abc_highrise_boq.pdf') do |b|
  b.tender = tender1
  b.status = 'uploaded'
  b.client_name = 'ABC Construction Ltd'
  b.client_reference = 'ABC-2024-REF-001'
  b.qs_name = 'John Smith'
  b.received_date = Date.new(2024, 1, 10)
  b.uploaded_by = rich
  b.notes = 'Initial BOQ for high-rise commercial building'
  b.header_row_index = 1
end

boq2 = Boq.find_or_create_by!(boq_name: 'XYZ Industrial - BOQ', file_name: 'xyz_industrial_boq.pdf') do |b|
  b.tender = tender2
  b.status = 'uploaded'
  b.client_name = 'XYZ Infrastructure'
  b.client_reference = 'XYZ-2024-REF-002'
  b.qs_name = 'Sarah Jones'
  b.received_date = Date.new(2024, 2, 15)
  b.uploaded_by = rich
  b.notes = 'Steel fabrication BOQ for industrial complex'
  b.header_row_index = 1
end

boq3 = Boq.find_or_create_by!(boq_name: 'Smart City Office - BOQ', file_name: 'smart_city_boq.pdf') do |b|
  b.tender = tender3
  b.status = 'uploaded'
  b.client_name = 'Smart City Developers'
  b.client_reference = 'SC-2024-REF-003'
  b.qs_name = 'Mark Wilson'
  b.received_date = Date.new(2024, 3, 5)
  b.uploaded_by = rich
  b.notes = 'Office complex BOQ'
  b.header_row_index = 1
end

boq4 = Boq.find_or_create_by!(boq_name: 'Heritage Renovations - BOQ', file_name: 'heritage_boq.pdf') do |b|
  b.tender = tender4
  b.status = 'uploaded'
  b.client_name = 'Heritage Renovations Inc'
  b.client_reference = 'HR-2024-REF-004'
  b.qs_name = 'Sarah Jones'
  b.received_date = Date.new(2024, 4, 1)
  b.uploaded_by = rich
  b.notes = 'Heritage building renovation BOQ'
  b.header_row_index = 1
end

# ===== BOQ ITEMS FOR BOQ1 =====
BoqItem.find_or_create_by!(boq: boq1, item_number: 'BOQ-001') do |bi|
  bi.item_description = 'Light Structural Steel - Up to 25 kg/m'
  bi.unit_of_measure = 'tonne'
  bi.quantity = 45.5
  bi.section_category = 'Steel Sections'
  bi.sequence_order = 1
  bi.page_number = '1'
  bi.notes = 'Supplied and erected on site'
end

BoqItem.find_or_create_by!(boq: boq1, item_number: 'BOQ-002') do |bi|
  bi.item_description = 'Heavy Structural Steel - Over 25 kg/m'
  bi.unit_of_measure = 'tonne'
  bi.quantity = 28.3
  bi.section_category = 'Steel Sections'
  bi.sequence_order = 2
  bi.page_number = '1'
  bi.notes = 'Supplied and erected on site'
end

BoqItem.find_or_create_by!(boq: boq1, item_number: 'BOQ-003') do |bi|
  bi.item_description = 'Bolts and Fasteners - M16 HD'
  bi.unit_of_measure = 'kg'
  bi.quantity = 250
  bi.section_category = 'M16 HD Bolt'
  bi.sequence_order = 3
  bi.page_number = '2'
  bi.notes = 'Grade 8.8 specifications'
end

BoqItem.find_or_create_by!(boq: boq1, item_number: 'BOQ-004') do |bi|
  bi.item_description = 'Shop Priming - All steel members'
  bi.unit_of_measure = 'tonne'
  bi.quantity = 73.8
  bi.section_category = 'Paintwork'
  bi.sequence_order = 4
  bi.page_number = '3'
  bi.notes = 'Zinc-rich epoxy primer'
end

# ===== BOQ ITEMS FOR BOQ2 =====
BoqItem.find_or_create_by!(boq: boq2, item_number: 'BOQ-001') do |bi|
  bi.item_description = 'Structural Steel Beams and Columns'
  bi.unit_of_measure = 'tonne'
  bi.quantity = 125.75
  bi.section_category = 'Steel Sections'
  bi.sequence_order = 1
  bi.page_number = '1'
  bi.notes = 'Various sizes for main structure'
end

BoqItem.find_or_create_by!(boq: boq2, item_number: 'BOQ-002') do |bi|
  bi.item_description = 'Hollow Sections - CHS'
  bi.unit_of_measure = 'tonne'
  bi.quantity = 45.25
  bi.section_category = 'Steel Sections'
  bi.sequence_order = 2
  bi.page_number = '1'
  bi.notes = 'Circular hollow sections'
end

BoqItem.find_or_create_by!(boq: boq2, item_number: 'BOQ-003') do |bi|
  bi.item_description = 'Welding and Connections'
  bi.unit_of_measure = 'metre'
  bi.quantity = 2500
  bi.section_category = 'Blank'
  bi.sequence_order = 3
  bi.page_number = '2'
  bi.notes = 'All connections as per drawings'
end

BoqItem.find_or_create_by!(boq: boq2, item_number: 'BOQ-004') do |bi|
  bi.item_description = 'Bolts - M20 HD'
  bi.unit_of_measure = 'kg'
  bi.quantity = 500
  bi.section_category = 'M20 HD Bolt'
  bi.sequence_order = 4
  bi.page_number = '3'
  bi.notes = 'High strength bolts'
end

BoqItem.find_or_create_by!(boq: boq2, item_number: 'BOQ-005') do |bi|
  bi.item_description = 'Final Paint - All exposed steel'
  bi.unit_of_measure = 'tonne'
  bi.quantity = 171.0
  bi.section_category = 'Paintwork'
  bi.sequence_order = 5
  bi.page_number = '4'
  bi.notes = '2-pack polyurethane finish'
end

# ===== BOQ ITEMS FOR BOQ3 =====
BoqItem.find_or_create_by!(boq: boq3, item_number: 'BOQ-001') do |bi|
  bi.item_description = 'Universal Beams - 254 x 254'
  bi.unit_of_measure = 'tonne'
  bi.quantity = 22.5
  bi.section_category = 'Steel Sections'
  bi.sequence_order = 1
  bi.page_number = '1'
  bi.notes = 'Main floor beams'
end

BoqItem.find_or_create_by!(boq: boq3, item_number: 'BOQ-002') do |bi|
  bi.item_description = 'Columns - UC 356 x 406'
  bi.unit_of_measure = 'tonne'
  bi.quantity = 18.75
  bi.section_category = 'Steel Sections'
  bi.sequence_order = 2
  bi.page_number = '1'
  bi.notes = 'Main support columns'
end

BoqItem.find_or_create_by!(boq: boq3, item_number: 'BOQ-003') do |bi|
  bi.item_description = 'Plate Material - Various thicknesses'
  bi.unit_of_measure = 'tonne'
  bi.quantity = 15.3
  bi.section_category = 'Steel Sections'
  bi.sequence_order = 3
  bi.page_number = '2'
  bi.notes = 'Connections and splices'
end

BoqItem.find_or_create_by!(boq: boq3, item_number: 'BOQ-004') do |bi|
  bi.item_description = 'Bolts - M24 HD'
  bi.unit_of_measure = 'kg'
  bi.quantity = 380
  bi.section_category = 'M24 HD Bolt'
  bi.sequence_order = 4
  bi.page_number = '2'
  bi.notes = 'Heavy duty connections'
end

BoqItem.find_or_create_by!(boq: boq3, item_number: 'BOQ-005') do |bi|
  bi.item_description = 'Galvanizing - Hot dip'
  bi.unit_of_measure = 'tonne'
  bi.quantity = 56.55
  bi.section_category = 'Paintwork'
  bi.sequence_order = 5
  bi.page_number = '3'
  bi.notes = 'All members to be galvanized'
end

# ===== BOQ ITEMS FOR BOQ4 =====
BoqItem.find_or_create_by!(boq: boq4, item_number: 'BOQ-001') do |bi|
  bi.item_description = 'Structural Repairs - Steel reinforcement'
  bi.unit_of_measure = 'tonne'
  bi.quantity = 12.5
  bi.section_category = 'Steel Sections'
  bi.sequence_order = 1
  bi.page_number = '1'
  bi.notes = 'Heritage building repairs'
end

BoqItem.find_or_create_by!(boq: boq4, item_number: 'BOQ-002') do |bi|
  bi.item_description = 'Bolts - M16 Chemical Anchor'
  bi.unit_of_measure = 'kg'
  bi.quantity = 120
  bi.section_category = 'M16 Chemical'
  bi.sequence_order = 2
  bi.page_number = '1'
  bi.notes = 'For masonry connections'
end

BoqItem.find_or_create_by!(boq: boq4, item_number: 'BOQ-003') do |bi|
  bi.item_description = 'Traditional Paint Finish'
  bi.unit_of_measure = 'tonne'
  bi.quantity = 12.5
  bi.section_category = 'Paintwork'
  bi.sequence_order = 3
  bi.page_number = '2'
  bi.notes = 'Heritage-appropriate finish'
end

# ===== TENDER CRANE SELECTIONS =====
# Get the crane rates
crane_10t_rsb = CraneRate.find_by(size: '10t', ownership_type: 'rsb_owned')
crane_25t_rental = CraneRate.find_by(size: '25t', ownership_type: 'rental')
crane_35t_rental = CraneRate.find_by(size: '35t', ownership_type: 'rental')
crane_50t_rental = CraneRate.find_by(size: '50t', ownership_type: 'rental')

if crane_10t_rsb && crane_25t_rental && crane_35t_rental && crane_50t_rental
  # ===== TENDER 1 (ABC High-Rise) - Multiple purpose selections =====
  # Main crane: 2x 10t RSB Owned for 20 days
  TenderCraneSelection.find_or_create_by!(tender: tender1, crane_rate: crane_10t_rsb, purpose: 'main', sort_order: 1) do |tcs|
    tcs.quantity = 2
    tcs.duration_days = 20
    tcs.wet_rate_per_day = 2050.00
    tcs.total_cost = 2050.00 * 2 * 20  # = 82,000
  end

  # Splicing crane: 1x 25t Rented for 14 days
  TenderCraneSelection.find_or_create_by!(tender: tender1, crane_rate: crane_25t_rental, purpose: 'splicing', sort_order: 2) do |tcs|
    tcs.quantity = 1
    tcs.duration_days = 14
    tcs.wet_rate_per_day = 4150.00
    tcs.total_cost = 4150.00 * 1 * 14  # = 58,100
  end

  # Miscellaneous: 1x 10t RSB Owned for 7 days
  TenderCraneSelection.find_or_create_by!(tender: tender1, crane_rate: crane_10t_rsb, purpose: 'main', sort_order: 3) do |tcs|
    tcs.quantity = 1
    tcs.duration_days = 7
    tcs.wet_rate_per_day = 2050.00
    tcs.total_cost = 2050.00 * 1 * 7  # = 14,350
  end

  # ===== TENDER 2 (XYZ Mining Operation) - Heavy crane requirements =====
  # Main crane: 3x 25t Rented for 30 days
  TenderCraneSelection.find_or_create_by!(tender: tender2, crane_rate: crane_25t_rental, purpose: 'main', sort_order: 1) do |tcs|
    tcs.quantity = 3
    tcs.duration_days = 30
    tcs.wet_rate_per_day = 4150.00
    tcs.total_cost = 4150.00 * 3 * 30  # = 373,500
  end

  # Splicing crane: 1x 35t Rented for 21 days
  TenderCraneSelection.find_or_create_by!(tender: tender2, crane_rate: crane_35t_rental, purpose: 'splicing', sort_order: 2) do |tcs|
    tcs.quantity = 1
    tcs.duration_days = 21
    tcs.wet_rate_per_day = 3850.00
    tcs.total_cost = 3850.00 * 1 * 21  # = 80,850
  end

  # Miscellaneous: 2x 10t RSB Owned for 10 days
  TenderCraneSelection.find_or_create_by!(tender: tender2, crane_rate: crane_10t_rsb, purpose: 'main', sort_order: 3) do |tcs|
    tcs.quantity = 2
    tcs.duration_days = 10
    tcs.wet_rate_per_day = 2050.00
    tcs.total_cost = 2050.00 * 2 * 10  # = 41,000
  end

  # ===== TENDER 3 (Smart City Office Complex) - Mid-range requirements =====
  # Main crane: 1x 25t Rented for 18 days
  TenderCraneSelection.find_or_create_by!(tender: tender3, crane_rate: crane_25t_rental, purpose: 'main', sort_order: 1) do |tcs|
    tcs.quantity = 1
    tcs.duration_days = 18
    tcs.wet_rate_per_day = 4150.00
    tcs.total_cost = 4150.00 * 1 * 18  # = 74,700
  end

  # Miscellaneous: 1x 10t RSB Owned for 5 days
  TenderCraneSelection.find_or_create_by!(tender: tender3, crane_rate: crane_10t_rsb, purpose: 'main', sort_order: 2) do |tcs|
    tcs.quantity = 1
    tcs.duration_days = 5
    tcs.wet_rate_per_day = 2050.00
    tcs.total_cost = 2050.00 * 1 * 5  # = 10,250
  end

  # ===== TENDER 4 (Heritage Renovations) - Light requirements =====
  # Main crane: 1x 10t RSB Owned for 8 days
  TenderCraneSelection.find_or_create_by!(tender: tender4, crane_rate: crane_10t_rsb, purpose: 'main', sort_order: 1) do |tcs|
    tcs.quantity = 1
    tcs.duration_days = 8
    tcs.wet_rate_per_day = 2050.00
    tcs.total_cost = 2050.00 * 1 * 8  # = 16,400
  end
end

# ===== PROJECT RATE BUILD-UPS (DEFAULT RATES PER TENDER) =====
# Tender 1: ABC High-Rise (Commercial - Standard rates)
ProjectRateBuildUp.find_or_create_by!(tender: tender1) do |prbu|
  prbu.material_supply_rate = 8500.00
  prbu.fabrication_rate = 4200.00
  prbu.overheads_rate = 1800.00
  prbu.shop_priming_rate = 350.00
  prbu.onsite_painting_rate = 400.00
  prbu.delivery_rate = 500.00
  prbu.bolts_rate = 200.00
  prbu.erection_rate = 300.00
  prbu.crainage_rate = 1200.00
  prbu.cherry_picker_rate = 150.00
  prbu.galvanizing_rate = 600.00
end

# Tender 2: XYZ Mining Operation (Mining - Higher rates due to complexity)
ProjectRateBuildUp.find_or_create_by!(tender: tender2) do |prbu|
  prbu.material_supply_rate = 9500.00
  prbu.fabrication_rate = 4800.00
  prbu.overheads_rate = 2200.00
  prbu.shop_priming_rate = 400.00
  prbu.onsite_painting_rate = 500.00
  prbu.delivery_rate = 750.00
  prbu.bolts_rate = 250.00
  prbu.erection_rate = 450.00
  prbu.crainage_rate = 1500.00
  prbu.cherry_picker_rate = 200.00
  prbu.galvanizing_rate = 800.00
end

# Tender 3: Smart City Office Complex (Commercial - Mid-range rates)
ProjectRateBuildUp.find_or_create_by!(tender: tender3) do |prbu|
  prbu.material_supply_rate = 8200.00
  prbu.fabrication_rate = 4000.00
  prbu.overheads_rate = 1700.00
  prbu.shop_priming_rate = 320.00
  prbu.onsite_painting_rate = 380.00
  prbu.delivery_rate = 450.00
  prbu.bolts_rate = 180.00
  prbu.erection_rate = 280.00
  prbu.crainage_rate = 1100.00
  prbu.cherry_picker_rate = 130.00
  prbu.galvanizing_rate = 550.00
end

# Tender 4: Heritage Renovations (Commercial - Heritage/Specialized rates)
ProjectRateBuildUp.find_or_create_by!(tender: tender4) do |prbu|
  prbu.material_supply_rate = 8800.00
  prbu.fabrication_rate = 4400.00
  prbu.overheads_rate = 1900.00
  prbu.shop_priming_rate = 380.00
  prbu.onsite_painting_rate = 450.00
  prbu.delivery_rate = 500.00
  prbu.bolts_rate = 210.00
  prbu.erection_rate = 320.00
  prbu.crainage_rate = 1000.00
  prbu.cherry_picker_rate = 140.00
  prbu.galvanizing_rate = 650.00
end

# ===== P&G ITEM TEMPLATES =====
pg_templates = [
  # Fixed Based
  { description: 'Site establishment & demobilisation', category: 'fixed' },
  { description: 'Site offices, containers, ablutions (initial setup)', category: 'fixed' },
  { description: 'Initial insurances, guarantees', category: 'fixed' },
  { description: 'Contractual documentation', category: 'fixed' },
  { description: 'Health & Safety file setup', category: 'fixed' },
  { description: 'Initial surveys / setting out', category: 'fixed' },
  { description: 'Site signage, fencing', category: 'fixed' },

  # Duration Based
  { description: 'Cranage', category: 'time_based', is_crane: true },
  { description: 'Cherry picker', category: 'time_based', is_access_equipment: true },
  { description: 'Site supervision (foreman, site agent allocation)', category: 'time_based' },
  { description: 'Temporary services (power, water, data)', category: 'time_based' },
  { description: 'Plant & equipment standing time (cranes if dedicated, telehandler, cherry picker)', category: 'time_based', is_crane: true },
  { description: 'Security', category: 'time_based' },
  { description: 'Site offices rental', category: 'time_based' },
  { description: 'H&S officer', category: 'time_based' },
  { description: 'Accommodation & travel', category: 'time_based' },

  # Percentage Based
  { description: 'Head office overhead allocation', category: 'percentage_based' },
  { description: 'Contract administration', category: 'percentage_based' },
  { description: 'Financial management', category: 'percentage_based' },
  { description: 'QA systems', category: 'percentage_based' },
  { description: 'IT systems', category: 'percentage_based' },
  { description: 'Corporate insurances not project-specific', category: 'percentage_based' }
]

pg_templates.each_with_index do |attrs, index|
  PreliminariesGeneralItemTemplate.find_or_create_by!(description: attrs[:description]) do |t|
    t.category = attrs[:category]
    t.is_crane = attrs[:is_crane] || false
    t.is_access_equipment = attrs[:is_access_equipment] || false
    t.sort_order = index + 1
  end
end

puts "  • P&G Templates: #{PreliminariesGeneralItemTemplate.count}"
# ===== ANCHOR RATES =====
anchor_rates_data = [
  { name: 'M8 Chemical Anchor', material_cost: 60.00 },
  { name: 'M10 Chemical Anchor', material_cost: 75.00 },
  { name: 'M12 Chemical Anchor', material_cost: 90.00 },
  { name: 'M16 Chemical Anchor', material_cost: 105.00 }
]

anchor_rates_data.each do |attrs|
  AnchorRate.find_or_create_by!(name: attrs[:name]) do |ar|
    ar.waste_percentage = 7.5
    ar.material_cost = attrs[:material_cost]
  end
end

puts "  • Anchor Rates: #{AnchorRate.count}"

# ===== NUT, BOLT, AND WASHER RATES =====
nut_bolt_washer_rates_data = [
  { name: 'M12 nut black', material_cost: 5.00 },
  { name: 'M12 nut EG', material_cost: 6.00 },
  { name: 'M12 nut HDG', material_cost: 7.00 }
]

nut_bolt_washer_rates_data.each do |attrs|
  NutBoltWasherRate.find_or_create_by!(name: attrs[:name]) do |nbw|
    nbw.waste_percentage = 7.5
    nbw.material_cost = attrs[:material_cost]
  end
end

puts "  • Nut, Bolt, and Washer Rates: #{NutBoltWasherRate.count}"

# ===== SECTION CATEGORY TEMPLATES =====
steel_sections = SectionCategory.find_by(display_name: 'Steel Sections')
if steel_sections
  template = SectionCategoryTemplate.find_or_create_by!(section_category: steel_sections)
  LineItemMaterialTemplate.find_or_create_by!(section_category_template: template, material_supply: MaterialSupply.first) do |lmt|
    lmt.proportion_percentage = 0.0
    lmt.waste_percentage = 7.5
  end
  # Ensure proportion is 0.0 even if record already exists
  LineItemMaterialTemplate.find_by(section_category_template: template, material_supply: MaterialSupply.first)&.update!(proportion_percentage: 0.0)

  # Additional templates for faster structure setup
  [
    'Local UB & UC Sections',
    'Sheets of Plate Decoil up to 12mm'
  ].each do |name|
    ms = MaterialSupply.find_by(name: name)
    next unless ms

    LineItemMaterialTemplate.find_or_create_by!(section_category_template: template, material_supply: ms) do |lmt|
      lmt.proportion_percentage = 0.0
      lmt.waste_percentage = ms.waste_percentage
    end
  end
end

m16_chemical = SectionCategory.find_by(display_name: 'M16 Chemical')
if m16_chemical
  template = SectionCategoryTemplate.find_or_create_by!(section_category: m16_chemical)
  anchor = AnchorRate.find_by(name: 'M16 Chemical Anchor')
  if anchor
    LineItemMaterialTemplate.find_or_create_by!(section_category_template: template, material_supply: anchor) do |lmt|
      lmt.proportion_percentage = 100.0
      lmt.waste_percentage = 7.5
    end
  end
end

bolts = SectionCategory.find_by(display_name: 'Bolts')
if bolts
  template = SectionCategoryTemplate.find_or_create_by!(section_category: bolts)
  bolt = NutBoltWasherRate.first
  if bolt
    LineItemMaterialTemplate.find_or_create_by!(section_category_template: template, material_supply: bolt) do |lmt|
      lmt.proportion_percentage = 100.0
      lmt.waste_percentage = 7.5
    end
  end
end

puts "✅ Database seeded successfully!"

puts ""
puts "📊 SEEDED DATA SUMMARY:"
puts "  • Users: #{User.count}
  • Section Categories: #{SectionCategory.count}
"
puts "  • Tenders: #{Tender.count}"
puts "  • Projects: #{Project.count}"
puts "  • Budget Categories: #{BudgetCategory.count}"
puts "  • Budget Allowances: #{BudgetAllowance.count}"
puts "  • Variation Orders: #{VariationOrder.count}"
puts "  • Claims: #{Claim.count}"
puts "  • Claim Line Items: #{ClaimLineItem.count}"
puts "  • Fabrication Records: #{FabricationRecord.count}"
puts "  • Suppliers: #{Supplier.count}"
puts "  • Material Supplies: #{MaterialSupply.count}"
puts "  • Monthly Material Supply Rates: #{MonthlyMaterialSupplyRate.count}"
puts "  • Material Supply Rates: #{MaterialSupplyRate.count}"
puts "  • Crane Rates: #{CraneRate.count}"
puts "  • Crane Complements: #{CraneComplement.count}"
puts "  • Project Rate Build-Ups: #{ProjectRateBuildUp.count}"
# ===== TENDER-SPECIFIC MATERIAL RATES (SAMPLE DATA) =====
# Create sample tender-specific rates for demonstration
if MaterialSupply.any? && Tender.any?
  tender1 = Tender.order(:id).first
  tender2 = Tender.order(:id).second
  
  materials = MaterialSupply.limit(3)
  
  if materials.any? && tender1
    # For tender1, set custom rates for first 2 materials
    materials.each_with_index do |material, idx|
      next if idx >= 2  # Only set rates for first 2 materials per tender
      
      rate_value = 15000.00 + (idx * 5000.00)
      TenderSpecificMaterialRate.find_or_create_by!(
        tender_id: tender1.id,
        material_supply_id: material.id
      ) do |rate|
        rate.rate = rate_value
        rate.unit = "per_tonne"
        rate.effective_from = Date.current - 30.days
        rate.effective_to = Date.current + 90.days
        rate.notes = "Negotiated rate with supplier for ABC High-Rise project"
      end
    end
  end
  
  # For tender2, set custom rates
  if materials.any? && tender2
    materials.each_with_index do |material, idx|
      next if idx >= 3  # Set rates for all 3 materials for tender2
      
      rate_value = 18000.00 + (idx * 4000.00)
      TenderSpecificMaterialRate.find_or_create_by!(
        tender_id: tender2.id,
        material_supply_id: material.id
      ) do |rate|
        rate.rate = rate_value
        rate.unit = "per_tonne"
        rate.effective_from = Date.current - 60.days
        rate.effective_to = nil  # Indefinite until changed
        rate.notes = "Special mining project pricing"
      end
    end
  end
end

puts "  • On-Site Mobile Crane Breakdowns: #{OnSiteMobileCraneBreakdown.count}"
puts "  • Tender Crane Selections: #{TenderCraneSelection.count}"
puts "  • BOQs: #{Boq.count}"
puts "  • BOQ Items: #{BoqItem.count}"
puts "  • Tender-Specific Material Rates: #{TenderSpecificMaterialRate.count}"
puts ""
puts "🔑 LOGIN CREDENTIALS:"
puts "  • Email: kody@llamapress.ai (Admin)"
puts "  • Email: john.smith@company.com (Project Manager)"
puts "  • Email: sarah.jones@company.com (Project Manager)"
puts "  • Email: mark.wilson@company.com (Approver)"
puts "  • Password: 123456 (for all accounts)"

# ===== EQUIPMENT TYPES =====
EQUIPMENT_TYPES = [
  # Electric Scissors (7 items)
  { category: 'electric_scissors', model: '1932RS', working_height_m: 7.6, 
    base_rate_monthly: 8962.30, diesel_allowance_monthly: 0.00 },
  { category: 'electric_scissors', model: '2032', working_height_m: 8.1, 
    base_rate_monthly: 10509.90, diesel_allowance_monthly: 0.00 },
  { category: 'electric_scissors', model: '2646', working_height_m: 9.7, 
    base_rate_monthly: 10019.12, diesel_allowance_monthly: 0.00 },
  { category: 'electric_scissors', model: '3246', working_height_m: 11.6, 
    base_rate_monthly: 14316.36, diesel_allowance_monthly: 0.00 },
  { category: 'electric_scissors', model: '1412', working_height_m: 14.0, 
    base_rate_monthly: 19306.84, diesel_allowance_monthly: 0.00 },
  { category: 'electric_scissors', model: '1614', working_height_m: 16.0, 
    base_rate_monthly: 22067.08, diesel_allowance_monthly: 0.00 },
  { category: 'electric_scissors', model: '2212', working_height_m: 22.0, 
    base_rate_monthly: 53796.06, diesel_allowance_monthly: 0.00 },
  
  # Diesel Scissors (4 items)
  { category: 'diesel_scissors', model: '260MRT', working_height_m: 9.7, 
    base_rate_monthly: 18611.48, diesel_allowance_monthly: 13000.00 },
  { category: 'diesel_scissors', model: '3394RT', working_height_m: 11.6, 
    base_rate_monthly: 22129.62, diesel_allowance_monthly: 13000.00 },
  { category: 'diesel_scissors', model: '4394RT', working_height_m: 14.5, 
    base_rate_monthly: 26951.56, diesel_allowance_monthly: 13000.00 },
  { category: 'diesel_scissors', model: '5394RT', working_height_m: 18.0, 
    base_rate_monthly: 30335.08, diesel_allowance_monthly: 18200.00 },
  
  # Electric Articulating Booms (6 items)
  { category: 'electric_articulating_booms', model: 'AB38W/N', working_height_m: 10.0, 
    base_rate_monthly: 24142.56, diesel_allowance_monthly: 0.00 },
  { category: 'electric_articulating_booms', model: 'E450AJ', working_height_m: 12.0, 
    base_rate_monthly: 28873.34, diesel_allowance_monthly: 0.00 },
  { category: 'electric_articulating_booms', model: 'E600JP', working_height_m: 12.5, 
    base_rate_monthly: 28334.86, diesel_allowance_monthly: 0.00 },
  { category: 'electric_articulating_booms', model: 'AB38W/N', working_height_m: 13.8, 
    base_rate_monthly: 23446.14, diesel_allowance_monthly: 0.00 },
  { category: 'electric_articulating_booms', model: 'E450AJ', working_height_m: 15.5, 
    base_rate_monthly: 28634.84, diesel_allowance_monthly: 0.00 },
  { category: 'electric_articulating_booms', model: 'E600JP', working_height_m: 20.0, 
    base_rate_monthly: 46349.56, diesel_allowance_monthly: 0.00 },
  
  # Diesel Articulating Booms (7 items)
  { category: 'diesel_articulating_booms', model: '340AJ', working_height_m: 12.5, 
    base_rate_monthly: 28136.64, diesel_allowance_monthly: 16500.00 },
  { category: 'diesel_articulating_booms', model: '450AJ', working_height_m: 15.5, 
    base_rate_monthly: 30021.32, diesel_allowance_monthly: 19500.00 },
  { category: 'diesel_articulating_booms', model: '510AJ', working_height_m: 17.0, 
    base_rate_monthly: 32405.26, diesel_allowance_monthly: 19500.00 },
  { category: 'diesel_articulating_booms', model: '520AJ', working_height_m: 18.0, 
    base_rate_monthly: 31301.80, diesel_allowance_monthly: 19500.00 },
  { category: 'diesel_articulating_booms', model: '600AJ', working_height_m: 20.0, 
    base_rate_monthly: 40486.70, diesel_allowance_monthly: 19500.00 },
  { category: 'diesel_articulating_booms', model: '800AJ', working_height_m: 26.0, 
    base_rate_monthly: 73045.66, diesel_allowance_monthly: 22500.00 },
  { category: 'diesel_articulating_booms', model: '1250AJP', working_height_m: 41.0, 
    base_rate_monthly: 165723.58, diesel_allowance_monthly: 22500.00 },
  
  # Diesel Telescopic Booms (6 items)
  { category: 'diesel_telescopic_booms', model: '660SJ', working_height_m: 22.0, 
    base_rate_monthly: 46900.76, diesel_allowance_monthly: 19500.00 },
  { category: 'diesel_telescopic_booms', model: '860SJ', working_height_m: 28.0, 
    base_rate_monthly: 79101.44, diesel_allowance_monthly: 22500.00 },
  { category: 'diesel_telescopic_booms', model: '1200SJP', working_height_m: 39.0, 
    base_rate_monthly: 147633.62, diesel_allowance_monthly: 19500.00 },
  { category: 'diesel_telescopic_booms', model: '1350SJP', working_height_m: 43.0, 
    base_rate_monthly: 160226.42, diesel_allowance_monthly: 22500.00 },
  { category: 'diesel_telescopic_booms', model: '1500SJP', working_height_m: 48.0, 
    base_rate_monthly: 222209.92, diesel_allowance_monthly: 19500.00 },
  { category: 'diesel_telescopic_booms', model: '1850SJP', working_height_m: 57.0, 
    base_rate_monthly: 278112.20, diesel_allowance_monthly: 22500.00 },
  
  # Telehandlers (1 item)
  { category: 'telehandler', model: 'TH4017', working_height_m: 17.0, 
    base_rate_monthly: 66231.98, diesel_allowance_monthly: 11700.00 },
]

EQUIPMENT_TYPES.each do |attrs|
  EquipmentType.find_or_create_by!(
    category: attrs[:category],
    model: attrs[:model]
  ) do |eq|
    eq.working_height_m = attrs[:working_height_m]
    eq.base_rate_monthly = attrs[:base_rate_monthly]
    eq.damage_waiver_pct = 0.06  # Always 6% per BR-023
    eq.diesel_allowance_monthly = attrs[:diesel_allowance_monthly]
    eq.is_active = true
  end
end

puts "  • Equipment Types: #{EquipmentType.count}"

# ===== PRELIMINARIES & GENERAL (P&G) ITEM TEMPLATES =====
# Fixed-Based Templates
[
  'Site establishment & demobilisation',
  'Site offices, containers, ablutions (initial setup)',
  'Initial insurances, guarantees',
  'Contractual documentation',
  'Health & Safety file setup',
  'Initial surveys / setting out',
  'Site signage, fencing'
].each_with_index do |desc, index|
  PreliminariesGeneralItemTemplate.find_or_create_by!(
    category: 'fixed',
    description: desc
  ) do |t|
    t.quantity = 1.0
    t.rate = 0.0
    t.sort_order = index + 1
  end
end

# Duration-Based Templates
[
  { desc: 'Crainage', is_crane: true },
  { desc: 'Cherry picker', is_access: true },
  { desc: 'Site supervision (foreman, site agent allocation)' },
  { desc: 'Temporary services (power, water, data)' },
  { desc: 'Plant & equipment standing time (cranes if dedicated, telehandler, cherry picker)', is_crane: true },
  { desc: 'Security' },
  { desc: 'Site offices rental' },
  { desc: 'H&S officer' },
  { desc: 'Accommodation & travel' }
].each_with_index do |item, index|
  PreliminariesGeneralItemTemplate.find_or_create_by!(
    category: 'time_based',
    description: item[:desc]
  ) do |t|
    t.quantity = 1.0
    t.rate = 0.0
    t.sort_order = index + 10
    t.is_crane = item[:is_crane] || false
    t.is_access_equipment = item[:is_access] || false
  end
end

# Percentage-Based Templates
[
  'Head office overhead allocation',
  'Contract administration',
  'Financial management',
  'QA systems',
  'IT systems',
  'Corporate insurances not project-specific'
].each_with_index do |desc, index|
  PreliminariesGeneralItemTemplate.find_or_create_by!(
    category: 'percentage_based',
    description: desc
  ) do |t|
    t.quantity = 0.0
    t.rate = 0.0
    t.sort_order = index + 20
  end
end

puts "  • P&G Item Templates: #{PreliminariesGeneralItemTemplate.count}"
