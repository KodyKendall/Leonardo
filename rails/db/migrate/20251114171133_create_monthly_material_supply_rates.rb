class CreateMonthlyMaterialSupplyRates < ActiveRecord::Migration[7.2]
  def change
    create_table :monthly_material_supply_rates do |t|
      t.date :effective_from
      t.date :effective_to

      t.timestamps
    end
  end
end
