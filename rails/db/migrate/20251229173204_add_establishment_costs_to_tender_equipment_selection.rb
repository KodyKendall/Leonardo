class AddEstablishmentCostsToTenderEquipmentSelection < ActiveRecord::Migration[7.2]
  def change
    add_column :tender_equipment_selections, :establishment_cost, :decimal
    add_column :tender_equipment_selections, :de_establishment_cost, :decimal
  end
end
