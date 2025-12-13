class AddIsWinnerToMaterialSupplyRates < ActiveRecord::Migration[7.2]
  def change
    add_column :material_supply_rates, :is_winner, :boolean, default: false, null: false
    add_index :material_supply_rates, [:monthly_material_supply_rate_id, :material_supply_id, :is_winner],
              name: 'index_material_supply_rates_on_winner'
  end
end
