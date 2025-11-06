# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#

# ===== USERS =====
admin_user = User.find_or_create_by!(email: 'kody@llamapress.ai') do |user|
  user.name = 'Kody Admin'
  user.password = '123456'
  user.password_confirmation = '123456'
  user.role = 'admin'
  user.admin = true
end

pm1 = User.find_or_create_by!(email: 'john.smith@company.com') do |user|
  user.name = 'John Smith'
  user.password = '123456'
  user.password_confirmation = '123456'
  user.role = 'project_manager'
end

pm2 = User.find_or_create_by!(email: 'sarah.jones@company.com') do |user|
  user.name = 'Sarah Jones'
  user.password = '123456'
  user.password_confirmation = '123456'
  user.role = 'project_manager'
end

approver = User.find_or_create_by!(email: 'mark.wilson@company.com') do |user|
  user.name = 'Mark Wilson'
  user.password = '123456'
  user.password_confirmation = '123456'
  user.role = 'approver'
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
  t.status = 'awarded'
  t.client_name = 'ABC Construction Ltd'
  t.tender_value = 500000.00
  t.project_type = 'commercial'
  t.notes = 'High-rise commercial building project'
end

tender2 = Tender.find_or_create_by!(e_number: 'E-2024-002') do |t|
  t.status = 'awarded'
  t.client_name = 'XYZ Infrastructure'
  t.tender_value = 1200000.00
  t.project_type = 'industrial'
  t.notes = 'Steel fabrication for industrial complex'
end

tender3 = Tender.find_or_create_by!(e_number: 'E-2024-003') do |t|
  t.status = 'submitted'
  t.client_name = 'Smart City Developers'
  t.tender_value = 350000.00
  t.project_type = 'commercial'
  t.notes = 'Office complex in downtown area'
end

tender4 = Tender.find_or_create_by!(e_number: 'E-2024-004') do |t|
  t.status = 'awarded'
  t.client_name = 'Heritage Renovations Inc'
  t.tender_value = 180000.00
  t.project_type = 'commercial'
end

# ===== PROJECTS (now create with tenders and users) =====
project1 = Project.find_or_create_by!(rsb_number: 'RSB-2024-001') do |p|
  p.tender = tender1
  p.project_status = 'active'
  p.project_start_date = Date.new(2024, 1, 15)
  p.project_end_date = Date.new(2024, 12, 31)
  p.budget_total = 500000.00
  p.actual_spend = 250000.00
  p.created_by = pm1
end

project2 = Project.find_or_create_by!(rsb_number: 'RSB-2024-002') do |p|
  p.tender = tender2
  p.project_status = 'active'
  p.project_start_date = Date.new(2024, 3, 1)
  p.project_end_date = Date.new(2025, 2, 28)
  p.budget_total = 1200000.00
  p.actual_spend = 450000.00
  p.created_by = pm2
end

project3 = Project.find_or_create_by!(rsb_number: 'RSB-2024-003') do |p|
  p.tender = tender4
  p.project_status = 'planning'
  p.project_start_date = Date.new(2024, 6, 1)
  p.project_end_date = Date.new(2024, 9, 30)
  p.budget_total = 180000.00
  p.actual_spend = 0.00
  p.created_by = pm1
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
  vo.created_by = pm1
  vo.approved_by = approver
  vo.approver_notes = 'Approved. Client acceptance required before work commences.'
  vo.approved_at = 5.days.ago
end

vo2 = VariationOrder.find_or_create_by!(vo_number: 'VO-2024-002') do |vo|
  vo.project = project1
  vo.vo_status = 'pending'
  vo.vo_amount = 15000.00
  vo.description = 'Expedited delivery of materials'
  vo.created_by = pm1
end

vo3 = VariationOrder.find_or_create_by!(vo_number: 'VO-2024-003') do |vo|
  vo.project = project2
  vo.vo_status = 'approved'
  vo.vo_amount = 45000.00
  vo.description = 'Additional fabrication capacity for accelerated timeline'
  vo.created_by = pm2
  vo.approved_by = approver
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
  c.submitted_by = pm1
  c.notes = 'First progress claim for works completed in April'
end

claim2 = Claim.find_or_create_by!(claim_number: 'CLM-2024-002') do |c|
  c.project = project1
  c.claim_date = Date.new(2024, 5, 31)
  c.claim_status = 'paid'
  c.total_claimed = 95000.00
  c.total_paid = 95000.00
  c.amount_due = 0.00
  c.submitted_by = pm1
  c.notes = 'Second progress claim for works completed in May'
end

claim3 = Claim.find_or_create_by!(claim_number: 'CLM-2024-003') do |c|
  c.project = project2
  c.claim_date = Date.new(2024, 4, 15)
  c.claim_status = 'submitted'
  c.total_claimed = 150000.00
  c.total_paid = 0.00
  c.amount_due = 150000.00
  c.submitted_by = pm2
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

puts "✅ Database seeded successfully!"
puts ""
puts "📊 SEEDED DATA SUMMARY:"
puts "  • Users: #{User.count}"
puts "  • Tenders: #{Tender.count}"
puts "  • Projects: #{Project.count}"
puts "  • Budget Categories: #{BudgetCategory.count}"
puts "  • Budget Allowances: #{BudgetAllowance.count}"
puts "  • Variation Orders: #{VariationOrder.count}"
puts "  • Claims: #{Claim.count}"
puts "  • Claim Line Items: #{ClaimLineItem.count}"
puts "  • Fabrication Records: #{FabricationRecord.count}"
puts ""
puts "🔑 LOGIN CREDENTIALS:"
puts "  • Email: kody@llamapress.ai (Admin)"
puts "  • Email: john.smith@company.com (Project Manager)"
puts "  • Email: sarah.jones@company.com (Project Manager)"
puts "  • Email: mark.wilson@company.com (Approver)"
puts "  • Password: 123456 (for all accounts)"
