class AddDefaultsAndIndexToNutBoltWasherRates < ActiveRecord::Migration[7.2]
  def change
    change_column_default :nut_bolt_washer_rates, :waste_percentage, from: nil, to: 7.5
    change_column_default :nut_bolt_washer_rates, :material_cost, from: nil, to: 0.0
    change_column_null :nut_bolt_washer_rates, :name, false
    add_index :nut_bolt_washer_rates, :name, unique: true
  end
end
