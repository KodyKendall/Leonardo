class CreateMaterialSupplyRates < ActiveRecord::Migration[7.2]
  def change
    create_table :material_supply_rates do |t|
      t.decimal :rate
      t.string :unit
      t.references :material_supply, null: false, foreign_key: true
      t.references :supplier, null: false, foreign_key: true
      t.references :monthly_material_supply_rate, null: false, foreign_key: true

      t.timestamps
    end
  end
end
