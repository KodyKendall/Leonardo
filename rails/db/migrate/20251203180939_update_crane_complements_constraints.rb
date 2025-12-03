class UpdateCraneComplementsConstraints < ActiveRecord::Migration[7.2]
  def change
    change_column :crane_complements, :area_min_sqm, :decimal, precision: 10, scale: 2, null: false
    change_column :crane_complements, :area_max_sqm, :decimal, precision: 10, scale: 2, null: false
    change_column :crane_complements, :crane_recommendation, :string, limit: 100, null: false
    change_column :crane_complements, :default_wet_rate_per_day, :decimal, precision: 12, scale: 2, null: false
  end
end
