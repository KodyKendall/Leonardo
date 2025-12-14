class ChangeColumnMaterialSupplyIncludedToDecimal < ActiveRecord::Migration[7.2]
  def up
    # Add a new temporary decimal column
    add_column :line_item_rate_build_ups, :material_supply_multiplier, :decimal, precision: 5, scale: 2

    # Backfill: true → 1.0, false → 0
    execute "UPDATE line_item_rate_build_ups SET material_supply_multiplier = CASE WHEN material_supply_included = true THEN 1.0 ELSE 0 END"

    # Remove the old boolean column
    remove_column :line_item_rate_build_ups, :material_supply_included

    # Rename the new column to the original name
    rename_column :line_item_rate_build_ups, :material_supply_multiplier, :material_supply_included
  end

  def down
    # Add a temporary boolean column
    add_column :line_item_rate_build_ups, :material_supply_included_bool, :boolean, default: true

    # Backfill: 1.0 or higher → true, 0 or lower → false
    execute "UPDATE line_item_rate_build_ups SET material_supply_included_bool = CASE WHEN material_supply_included >= 1.0 THEN true ELSE false END"

    # Remove the decimal column
    remove_column :line_item_rate_build_ups, :material_supply_included

    # Rename the temporary column back
    rename_column :line_item_rate_build_ups, :material_supply_included_bool, :material_supply_included
  end
end
