class AddProfitMarginPercentageToProjectRateBuildUps < ActiveRecord::Migration[7.2]
  def change
    add_column :project_rate_build_ups, :profit_margin_percentage, :decimal, precision: 10, scale: 2
  end
end
