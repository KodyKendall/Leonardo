class CreateLineItemRateBuildUps < ActiveRecord::Migration[7.2]
  def change
    create_table :line_item_rate_build_ups do |t|
      t.references :tender_line_item, null: false, foreign_key: true
      t.decimal :material_supply_rate, precision: 12, scale: 2, default: 0.0
      t.decimal :fabrication_rate, precision: 12, scale: 2, default: 0.0
      t.boolean :fabrication_included, default: true
      t.decimal :overheads_rate, precision: 12, scale: 2, default: 0.0
      t.boolean :overheads_included, default: true
      t.decimal :shop_priming_rate, precision: 12, scale: 2, default: 0.0
      t.boolean :shop_priming_included, default: false
      t.decimal :onsite_painting_rate, precision: 12, scale: 2, default: 0.0
      t.boolean :onsite_painting_included, default: false
      t.decimal :delivery_rate, precision: 12, scale: 2, default: 0.0
      t.boolean :delivery_included, default: true
      t.decimal :bolts_rate, precision: 12, scale: 2, default: 0.0
      t.boolean :bolts_included, default: true
      t.decimal :erection_rate, precision: 12, scale: 2, default: 0.0
      t.boolean :erection_included, default: true
      t.decimal :crainage_rate, precision: 12, scale: 2, default: 0.0
      t.boolean :crainage_included, default: false
      t.decimal :cherry_picker_rate, precision: 12, scale: 2, default: 0.0
      t.boolean :cherry_picker_included, default: true
      t.decimal :galvanizing_rate, precision: 12, scale: 2, default: 0.0
      t.boolean :galvanizing_included, default: false
      t.decimal :subtotal, precision: 12, scale: 2, default: 0.0
      t.decimal :margin_amount, precision: 12, scale: 2, default: 0.0
      t.decimal :total_before_rounding, precision: 12, scale: 2, default: 0.0
      t.decimal :rounded_rate, precision: 12, scale: 2, default: 0.0

      t.timestamps
    end
  end
end
