class CreateNutBoltWasherRates < ActiveRecord::Migration[7.2]
  def change
    create_table :nut_bolt_washer_rates do |t|
      t.string :name
      t.decimal :waste_percentage, precision: 5, scale: 2
      t.decimal :material_cost, precision: 15, scale: 2

      t.timestamps
    end
  end
end
