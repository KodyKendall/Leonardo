class AddFieldsToNutBoltWasherRates < ActiveRecord::Migration[7.2]
  def change
    add_column :nut_bolt_washer_rates, :calculation_breakdown, :text
    add_column :nut_bolt_washer_rates, :mass_per_each, :decimal, precision: 10, scale: 3
  end
end
