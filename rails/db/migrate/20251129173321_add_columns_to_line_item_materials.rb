class AddColumnsToLineItemMaterials < ActiveRecord::Migration[7.2]
  def change
    add_column :line_item_materials, :thickness, :decimal
    add_column :line_item_materials, :rate, :decimal
    add_column :line_item_materials, :quantity, :decimal
  end
end
