class MakeRateNullableInTenderSpecificMaterialRates < ActiveRecord::Migration[7.2]
  def change
    change_column_null :tender_specific_material_rates, :rate, true
  end
end
