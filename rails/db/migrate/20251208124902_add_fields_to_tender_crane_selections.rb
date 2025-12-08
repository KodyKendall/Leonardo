class AddFieldsToTenderCraneSelections < ActiveRecord::Migration[7.2]
  def change
    add_column :tender_crane_selections, :purpose, :string, limit: 20, null: false, default: "main"
    add_column :tender_crane_selections, :quantity, :integer, null: false, default: 1
    add_column :tender_crane_selections, :duration_days, :integer, null: false
    add_column :tender_crane_selections, :wet_rate_per_day, :decimal, precision: 12, scale: 2, null: false
    add_column :tender_crane_selections, :total_cost, :decimal, precision: 14, scale: 2, default: 0.0
    add_column :tender_crane_selections, :sort_order, :integer, default: 0
  end
end
