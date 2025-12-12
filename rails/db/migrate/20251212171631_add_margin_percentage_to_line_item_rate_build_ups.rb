class AddMarginPercentageToLineItemRateBuildUps < ActiveRecord::Migration[7.2]
  def change
    add_column :line_item_rate_build_ups, :margin_percentage, :decimal, precision: 5, scale: 2, default: 0.0, null: false
  end
end
