class CreateEquipmentTypes < ActiveRecord::Migration[7.2]
  def change
    create_table :equipment_types do |t|
      t.string :category, limit: 50, null: false
      t.string :model, limit: 50, null: false
      t.decimal :working_height_m, precision: 5, scale: 1
      t.decimal :base_rate_monthly, precision: 12, scale: 2, null: false
      t.decimal :damage_waiver_pct, precision: 5, scale: 4, null: false, default: 0.06
      t.decimal :diesel_allowance_monthly, precision: 10, scale: 2, null: false, default: 0.0
      t.boolean :is_active, null: false, default: true

      t.timestamps
    end

    add_index :equipment_types, [:category, :model], unique: true, 
              name: 'index_equipment_types_on_category_and_model'
    add_index :equipment_types, :category
    add_index :equipment_types, :is_active
  end
end
