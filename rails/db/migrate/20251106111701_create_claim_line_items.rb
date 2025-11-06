class CreateClaimLineItems < ActiveRecord::Migration[7.2]
  def change
    create_table :claim_line_items do |t|
      t.references :claim, foreign_key: true, null: false
      t.string :line_item_description
      t.decimal :tender_rate, precision: 12, scale: 2
      t.decimal :claimed_quantity, precision: 10, scale: 3, default: 0
      t.decimal :claimed_amount, precision: 12, scale: 2, default: 0
      t.decimal :cumulative_quantity, precision: 10, scale: 3, default: 0
      t.boolean :is_new_item, default: false
      t.decimal :price_escalation, precision: 12, scale: 2, default: 0

      t.timestamps
    end
  end
end
