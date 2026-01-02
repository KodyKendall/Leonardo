class ReorderAndRefineMaterialSupplies < ActiveRecord::Migration[7.2]
  def up
    # 1. Handle "Sheets of Plate" rename/merge
    old_item = MaterialSupply.find_by(name: "Sheets of Plate")
    new_item = MaterialSupply.find_by(name: "Sheets of Plate Decoil up to 12mm")

    if old_item && new_item
      # Move material_supply_rates from old to new if both exist
      old_item.material_supply_rates.each do |rate|
        existing_rate = new_item.material_supply_rates.find_by(
          supplier_id: rate.supplier_id,
          monthly_material_supply_rate_id: rate.monthly_material_supply_rate_id
        )
        if existing_rate
          rate.destroy
        else
          rate.update!(material_supply_id: new_item.id)
        end
      end

      # Move tender_specific_material_rates from old to new if both exist
      old_item.tender_specific_material_rates.each do |rate|
        existing_rate = new_item.tender_specific_material_rates.find_by(tender_id: rate.tender_id)
        if existing_rate
          rate.destroy
        else
          rate.update!(material_supply_id: new_item.id)
        end
      end
      
      old_item.destroy
    elsif old_item
      old_item.update!(name: "Sheets of Plate Decoil up to 12mm")
    end

    # 2. Ensure "Sheets of Plate As Rolled 16mm & up" exists
    as_rolled = MaterialSupply.find_or_create_by!(name: "Sheets of Plate As Rolled 16mm & up") do |ms|
      ms.waste_percentage = 12.50
    end
    as_rolled.update!(waste_percentage: 12.50) # Ensure waste is correct if it existed

    # 3. Update positions
    ordered_names = [
      "UnEqual Angles",
      "Equal Angles",
      "Large Equal Angles",
      "Local UB & UC Sections",
      "Import UB & UC Sections",
      "PFC Sections",
      "Heavy PFC Sections",
      "IPE Sections",
      "Sheets of Plate Decoil up to 12mm",
      "Sheets of Plate As Rolled 16mm & up",
      "Cut to Size Plate",
      "Standard Hollow Sections",
      "Non-Standard Hollow Sections",
      "Gutters",
      "Round Bar",
      "CFLC - Black",
      "CFLC - Primed",
      "CFLC - Pregalv",
      "CFLC Metsec Alternative 1.6mm",
      "CFLC Metsec Alternative 2mm",
      "CFLC - Black 100mm Leg",
      "CFLC - Primed 100mm Leg",
      "CFLC - Pregalv 100mm Leg"
    ]

    ordered_names.each_with_index do |name, index|
      ms = MaterialSupply.find_by(name: name)
      ms.update!(position: index + 1) if ms
    end
  end

  def down
    # (Note: we don't strictly need to revert as this is a data cleanup migration,
    # but we could try to rename "Sheets of Plate Decoil up to 12mm" back if we wanted.)
  end
end
