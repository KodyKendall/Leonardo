class RemoveMaterialSupplyForeignKeys < ActiveRecord::Migration[7.2]
  def change
    remove_foreign_key :line_item_material_templates, :material_supplies
    remove_foreign_key :line_item_materials, :material_supplies
    remove_foreign_key :tender_specific_material_rates, :material_supplies
  end
end
