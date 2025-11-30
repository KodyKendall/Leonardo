class AllowNullMaterialSupplyInLineItemMaterials < ActiveRecord::Migration[7.2]
  def change
    change_column_null :line_item_materials, :material_supply_id, true
  end
end
