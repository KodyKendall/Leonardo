class BackfillMaterialSupplyTypeInTenderSpecificMaterialRates < ActiveRecord::Migration[7.2]
  def up
    TenderSpecificMaterialRate.where(material_supply_type: nil).update_all(material_supply_type: 'MaterialSupply')
  end

  def down
    # No-op as we want to keep it consistent
  end
end
