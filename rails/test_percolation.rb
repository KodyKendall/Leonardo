#!/usr/bin/env rails runner

require 'factory_bot_rails'

# Setup logging
Rails.logger.info "Starting percolation test..."

# Create test data
puts "Creating tender..."
tender = Tender.create!(
  project_name: "Test Project",
  tender_status: "Active"
)

puts "Creating inclusions with fabrication_included=false..."
inclusions = TenderInclusionsExclusion.create!(
  tender: tender,
  fabrication_included: false,
  delivery_included: false,
  overheads_included: true,
  primer_included: false,
  final_paint_included: false,
  bolts_included: true,
  erection_included: true,
  crainage_included: false,
  cherry_pickers_included: true,
  steel_galvanized: false
)

puts "Creating line item..."
line_item = TenderLineItem.create!(
  tender: tender,
  quantity: 100,
  rate: 50,
  page_number: "Page 1",
  item_number: "1.1",
  item_description: "Steel Work",
  unit_of_measure: "kg",
  section_category: "Steel Sections"
)

puts "\n🪲 Initial state:"
puts "  inclusions.fabrication_included: #{inclusions.fabrication_included}"
puts "  line_item.line_item_rate_build_up.fabrication_included: #{line_item.line_item_rate_build_up.fabrication_included}"

puts "\n🪲 Updating inclusions.fabrication_included to true..."
inclusions.update!(fabrication_included: true)

puts "\n🪲 After update:"
puts "  inclusions.fabrication_included: #{inclusions.fabrication_included}"
puts "  line_item.line_item_rate_build_up.reload.fabrication_included: #{line_item.line_item_rate_build_up.reload.fabrication_included}"

if line_item.line_item_rate_build_up.reload.fabrication_included == 1.0
  puts "\n✅ Percolation WORKS!"
else
  puts "\n❌ Percolation FAILED!"
end
