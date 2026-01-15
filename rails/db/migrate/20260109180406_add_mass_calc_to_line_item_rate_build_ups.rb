class AddMassCalcToLineItemRateBuildUps < ActiveRecord::Migration[7.2]
  def change
    add_column :line_item_rate_build_ups, :mass_calc, :decimal, precision: 15, scale: 4, default: 1.0
  end
end
