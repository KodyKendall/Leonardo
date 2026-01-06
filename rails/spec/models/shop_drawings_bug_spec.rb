require 'rails_helper'

RSpec.describe "Shop Drawings Double Counting", type: :model do
  let(:tender) { create(:tender) }
  let(:project_rate_buildup) { ProjectRateBuildUp.find_or_create_by!(tender: tender) }
  let!(:line_item) do
    create(:tender_line_item, 
      tender: tender, 
      quantity: 10, 
      unit_of_measure: "tonne",
      is_heading: false
    )
  end
  let(:rate_buildup) { line_item.line_item_rate_build_up }

  before do
    # Reset all rates to 0 for clarity
    project_rate_buildup.update!(
      material_supply_rate: 0,
      fabrication_rate: 0,
      overheads_rate: 0,
      shop_priming_rate: 0,
      onsite_painting_rate: 0,
      delivery_rate: 0,
      bolts_rate: 0,
      erection_rate: 0,
      crainage_rate: 0,
      cherry_picker_rate: 0,
      galvanizing_rate: 0,
      shop_drawings_rate: 0,
      profit_margin_percentage: 0
    )
    
    # Ensure line item rate buildup is also zeroed and synced
    rate_buildup.update!(
      material_supply_rate: 0,
      fabrication_rate: 0,
      overheads_rate: 0,
      shop_priming_rate: 0,
      onsite_painting_rate: 0,
      delivery_rate: 0,
      bolts_rate: 0,
      erection_rate: 0,
      crainage_rate: 0,
      cherry_picker_rate: 0,
      galvanizing_rate: 0,
      shop_drawings_rate: 0,
      margin_percentage: 0,
      fabrication_included: 1.0
    )
    
    tender.recalculate_total_tonnage!
    tender.recalculate_grand_total!
  end

  it "does not double count shop drawings in the grand total" do
    # 1. Set a shop drawings rate
    shop_drawings_rate = 500
    project_rate_buildup.update!(shop_drawings_rate: shop_drawings_rate)
    
    # Reload EVERYTHING to ensure association caches are cleared
    tender.reload
    
    # The sync should have pushed this to the line item
    rate_buildup.reload
    expect(rate_buildup.shop_drawings_rate).to eq(shop_drawings_rate)
    
    # Manually trigger recalculation to be sure
    tender.recalculate_grand_total!
    
    tender.reload
    puts "🪲 DEBUG AFTER: tender.grand_total=#{tender.grand_total}"
    puts "🪲 DEBUG AFTER: line_item.rate=#{line_item.reload.rate}"
    puts "🪲 DEBUG AFTER: shop_drawings_total=#{tender.project_rate_buildup.shop_drawings_total}"
    
    expect(tender.grand_total).to eq(5000), "Grand total should only include shop drawings once (as a tender-level lump sum). Found: #{tender.grand_total}"
  end
  
  it "does not include shop drawings rate in LineItemMaterialBreakdown subtotal" do
    # The user specifically mentioned "Tender Line Item Breakdown's Subtotal"
    # We should ensure it's not somehow leaking into LineItemMaterialBreakdown
    
    shop_drawings_rate = 500
    project_rate_buildup.update!(shop_drawings_rate: shop_drawings_rate)
    
    breakdown = line_item.line_item_material_breakdown
    expect(breakdown.subtotal).to eq(0), "Shop drawings rate should NOT affect the material breakdown subtotal"
  end
end
