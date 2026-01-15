class AddSupplierToTenderSpecificMaterialRates < ActiveRecord::Migration[7.2]
  def change
    add_reference :tender_specific_material_rates, :supplier, null: true, foreign_key: true
  end
end
