class RemoveUniqueConstraintFromLineItemMaterials < ActiveRecord::Migration[7.2]
  def change
    remove_index :line_item_materials, [:tender_line_item_id, :material_supply_id], unique: true
    add_index :line_item_materials, [:tender_line_item_id, :material_supply_id]
  end
end
