class CreateCraneComplements < ActiveRecord::Migration[7.2]
  def change
    create_table :crane_complements do |t|
      t.decimal :area_min_sqm
      t.decimal :area_max_sqm
      t.string :crane_recommendation
      t.decimal :default_wet_rate_per_day

      t.timestamps
    end
  end
end
