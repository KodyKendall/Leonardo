class AddMarginPercentageToLineItemMaterialBreakdowns < ActiveRecord::Migration[7.2]
  def change
    add_column :line_item_material_breakdowns, :margin_percentage, :decimal, precision: 5, scale: 2, default: 0.0, null: false
  end
end
