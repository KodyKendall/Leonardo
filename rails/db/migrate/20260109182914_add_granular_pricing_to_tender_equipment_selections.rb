class AddGranularPricingToTenderEquipmentSelections < ActiveRecord::Migration[7.2]
  def change
    add_column :tender_equipment_selections, :base_rate, :decimal, precision: 12, scale: 2
    add_column :tender_equipment_selections, :damage_waiver_pct, :decimal, precision: 5, scale: 4
    add_column :tender_equipment_selections, :diesel_allowance, :decimal, precision: 10, scale: 2
  end
end
