class AddShopDrawingsTonnesToProjectRateBuildUps < ActiveRecord::Migration[7.2]
  def change
    add_column :project_rate_build_ups, :shop_drawings_tonnes, :decimal, precision: 12, scale: 3
  end
end
