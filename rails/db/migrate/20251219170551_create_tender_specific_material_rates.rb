class CreateTenderSpecificMaterialRates < ActiveRecord::Migration[7.2]
  def change
    create_table :tender_specific_material_rates do |t|
      t.bigint :tender_id, null: false
      t.bigint :material_supply_id, null: false
      t.decimal :rate, precision: 12, scale: 2, null: false
      t.string :unit
      t.date :effective_from
      t.date :effective_to
      t.text :notes

      t.timestamps
    end

    # Foreign keys
    add_foreign_key :tender_specific_material_rates, :tenders, on_delete: :cascade
    add_foreign_key :tender_specific_material_rates, :material_supplies, on_delete: :cascade

    # Indexes for performance and uniqueness
    add_index :tender_specific_material_rates, :tender_id
    add_index :tender_specific_material_rates, :material_supply_id
    add_index :tender_specific_material_rates, [:tender_id, :material_supply_id], unique: true, name: "idx_tender_material_unique"
  end
end
