class AddRoundingIntervalToLineItemRateBuildUps < ActiveRecord::Migration[7.2]
  def change
    add_column :line_item_rate_build_ups, :rounding_interval, :integer, default: 50
  end
end
