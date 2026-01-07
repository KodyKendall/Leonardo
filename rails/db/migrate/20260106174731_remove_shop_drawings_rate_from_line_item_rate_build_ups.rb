class RemoveShopDrawingsRateFromLineItemRateBuildUps < ActiveRecord::Migration[7.2]
  def change
    remove_column :line_item_rate_build_ups, :shop_drawings_rate, :decimal
  end
end
