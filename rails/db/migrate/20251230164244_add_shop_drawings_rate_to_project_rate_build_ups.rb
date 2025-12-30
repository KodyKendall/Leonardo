class AddShopDrawingsRateToProjectRateBuildUps < ActiveRecord::Migration[7.2]
  def change
    add_column :project_rate_build_ups, :shop_drawings_rate, :decimal, precision: 12, scale: 2, default: 0.0
  end
end
