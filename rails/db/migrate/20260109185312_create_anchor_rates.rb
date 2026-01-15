class CreateAnchorRates < ActiveRecord::Migration[7.2]
  def change
    create_table :anchor_rates do |t|
      t.string :name, null: false
      t.decimal :waste_percentage, precision: 5, scale: 2, default: 7.5
      t.decimal :material_cost, precision: 15, scale: 2, default: 0.0

      t.timestamps
    end
    add_index :anchor_rates, :name, unique: true
  end
end
