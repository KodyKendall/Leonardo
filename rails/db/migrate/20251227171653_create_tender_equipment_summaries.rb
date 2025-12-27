class CreateTenderEquipmentSummaries < ActiveRecord::Migration[7.2]
  def change
    create_table :tender_equipment_summaries do |t|
      t.references :tender, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.decimal :equipment_subtotal, precision: 14, scale: 2, null: false, default: 0.0
      t.decimal :mobilization_fee, precision: 10, scale: 2, null: false, default: 15000.0
      t.decimal :total_equipment_cost, precision: 14, scale: 2, null: false, default: 0.0
      t.decimal :rate_per_tonne_raw, precision: 12, scale: 4
      t.decimal :rate_per_tonne_rounded, precision: 12, scale: 2

      t.timestamps
    end

    # Add unique index on tender_id (one summary per tender)
    add_index :tender_equipment_summaries, :tender_id, unique: true
  end
end
