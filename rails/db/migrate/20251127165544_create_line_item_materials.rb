class CreateLineItemMaterials < ActiveRecord::Migration[7.2]
  def change
    create_table :line_item_materials do |t|
      t.references :tender_line_item, null: false, foreign_key: true
      t.references :material_supply, null: false, foreign_key: true
      t.decimal :proportion, precision: 5, scale: 4, default: 0.0

      t.timestamps
    end
    
    add_index :line_item_materials, [:tender_line_item_id, :material_supply_id], unique: true
  end
end
