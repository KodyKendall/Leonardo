class CreateAnchorSupplierRates < ActiveRecord::Migration[7.2]
  def change
    create_table :anchor_supplier_rates, if_not_exists: true do |t|
      t.references :anchor_rate, null: false, foreign_key: true
      t.references :supplier, null: false, foreign_key: true
      t.decimal :rate, precision: 15, scale: 2, default: 0.0, null: false
      t.boolean :is_winner, default: false, null: false

      t.timestamps
    end

    unless index_exists?(:anchor_supplier_rates, [:anchor_rate_id, :supplier_id], name: "index_anchor_supplier_rates_on_anchor_and_supplier")
      add_index :anchor_supplier_rates, [:anchor_rate_id, :supplier_id], unique: true, name: "index_anchor_supplier_rates_on_anchor_and_supplier"
    end
  end
end
