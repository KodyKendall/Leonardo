class CreateFabricationRecords < ActiveRecord::Migration[7.2]
  def change
    create_table :fabrication_records do |t|
      t.references :project, foreign_key: true, null: false
      t.date :record_month, null: false
      t.decimal :tonnes_fabricated, precision: 10, scale: 3, default: 0
      t.decimal :allowed_rate, precision: 12, scale: 2, default: 0
      t.decimal :allowed_amount, precision: 12, scale: 2, default: 0
      t.decimal :actual_spend, precision: 12, scale: 2, default: 0

      t.timestamps
    end

    add_index :fabrication_records, [:project_id, :record_month], unique: true
  end
end
