class RenameProportionToProportionPercentage < ActiveRecord::Migration[7.2]
  def change
    rename_column :line_item_materials, :proportion, :proportion_percentage
    change_column :line_item_materials, :proportion_percentage, :decimal, precision: 5, scale: 2, default: "0.0"
  end
end
