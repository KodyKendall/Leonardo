class AddMaterialSupplyIncludedToLineItemRateBuildUps < ActiveRecord::Migration[7.2]
  def change
    add_column :line_item_rate_build_ups, :material_supply_included, :boolean, default: true
  end
end
