class CreateTenderEquipmentSelections < ActiveRecord::Migration[7.2]
  def change
    create_table :tender_equipment_selections do |t|
      t.references :tender, null: false, foreign_key: { on_delete: :cascade }
      t.references :equipment_type, null: false, foreign_key: true
      t.integer :units_required, null: false, default: 1
      t.integer :period_months, null: false, default: 1
      t.string :purpose, limit: 100
      t.decimal :monthly_cost_override, precision: 12, scale: 2
      t.decimal :calculated_monthly_cost, precision: 12, scale: 2, null: false
      t.decimal :total_cost, precision: 14, scale: 2, null: false, default: 0.0
      t.integer :sort_order, default: 0

      t.timestamps
    end

    # t.references already creates indexes for :tender_id and :equipment_type_id
    # Add composite index for sorting
    add_index :tender_equipment_selections, [:tender_id, :sort_order], 
              name: 'index_tender_equipment_selections_on_tender_sort'
  end
end
