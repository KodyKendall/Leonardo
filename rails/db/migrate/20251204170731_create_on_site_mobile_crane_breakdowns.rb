class CreateOnSiteMobileCraneBreakdowns < ActiveRecord::Migration[7.2]
  def change
    create_table :on_site_mobile_crane_breakdowns do |t|
      t.bigint :tender_id, null: false
      t.decimal :total_roof_area_sqm, precision: 12, scale: 2, default: 0.0
      t.decimal :erection_rate_sqm_per_day, precision: 10, scale: 2, default: 0.0
      t.integer :program_duration_days, default: 0
      t.string :ownership_type, limit: 20, default: 'rental'
      t.boolean :splicing_crane_required, default: false
      t.string :splicing_crane_size, limit: 10
      t.integer :splicing_crane_days, default: 0
      t.boolean :misc_crane_required, default: false
      t.string :misc_crane_size, limit: 10
      t.integer :misc_crane_days, default: 0

      t.timestamps
    end
    add_index :on_site_mobile_crane_breakdowns, :tender_id, unique: true
    add_foreign_key :on_site_mobile_crane_breakdowns, :tenders, column: :tender_id, on_delete: :cascade
  end
end
