class MakeMaterialSupplyPolymorphic < ActiveRecord::Migration[7.2]
  def up
    add_column :line_item_materials, :material_supply_type, :string
    add_column :line_item_material_templates, :material_supply_type, :string
    add_column :tender_specific_material_rates, :material_supply_type, :string

    # Backfill existing records
    execute "UPDATE line_item_materials SET material_supply_type = 'MaterialSupply' WHERE material_supply_id IS NOT NULL"
    execute "UPDATE line_item_material_templates SET material_supply_type = 'MaterialSupply' WHERE material_supply_id IS NOT NULL"
    execute "UPDATE tender_specific_material_rates SET material_supply_type = 'MaterialSupply' WHERE material_supply_id IS NOT NULL"

    # Add indexes for polymorphic lookup
    add_index :line_item_materials, [:material_supply_id, :material_supply_type], name: 'index_line_item_materials_on_material_supply'
    add_index :line_item_material_templates, [:material_supply_id, :material_supply_type], name: 'index_line_item_material_templates_on_material_supply'
    add_index :tender_specific_material_rates, [:material_supply_id, :material_supply_type], name: 'index_tender_specific_material_rates_on_material_supply'
  end

  def down
    remove_index :line_item_materials, name: 'index_line_item_materials_on_material_supply'
    remove_index :line_item_material_templates, name: 'index_line_item_material_templates_on_material_supply'
    remove_index :tender_specific_material_rates, name: 'index_tender_specific_material_rates_on_material_supply'

    remove_column :line_item_materials, :material_supply_type
    remove_column :line_item_material_templates, :material_supply_type
    remove_column :tender_specific_material_rates, :material_supply_type
  end
end
