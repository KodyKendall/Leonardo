class CreateTenderLineItems < ActiveRecord::Migration[7.2]
  def change
    create_table :tender_line_items do |t|
      t.references :tender, null: false, foreign_key: true
      t.decimal :quantity, precision: 12, scale: 2, default: "0.0"
      t.decimal :rate, precision: 12, scale: 2, default: "0.0"

      t.timestamps
    end
  end
end
