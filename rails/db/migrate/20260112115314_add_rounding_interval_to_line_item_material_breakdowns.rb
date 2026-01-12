class AddRoundingIntervalToLineItemMaterialBreakdowns < ActiveRecord::Migration[7.2]
  def change
    add_column :line_item_material_breakdowns, :rounding_interval, :integer, default: 50
  end
end
