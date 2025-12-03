class CreateCraneRates < ActiveRecord::Migration[7.2]
  def change
    create_table :crane_rates do |t|
      t.string :size, null: false
      t.string :ownership_type, null: false, default: 'rental'
      t.decimal :dry_rate_per_day, precision: 12, scale: 2, null: false
      t.decimal :diesel_per_day, precision: 12, scale: 2, null: false, default: 0
      t.boolean :is_active, default: true
      t.date :effective_from, null: false

      t.timestamps
    end
  end
end
