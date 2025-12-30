class AddEstablishmentCostToTenderEquipmentSummaries < ActiveRecord::Migration[7.2]
  def change
    add_column :tender_equipment_summaries, :establishment_cost, :decimal, default: 15000.0
  end
end
