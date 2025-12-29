class CreateRateBuildupCustomItems < ActiveRecord::Migration[7.2]
  def change
    create_table :rate_buildup_custom_items do |t|
      t.references :line_item_rate_build_up, null: false, foreign_key: { on_delete: :cascade }
      t.text :description, null: false
      t.decimal :rate, precision: 12, scale: 2, default: 0.0, null: false
      t.decimal :included, precision: 5, scale: 2, default: 1.0, null: false
      t.integer :sort_order, default: 0

      t.timestamps
    end
  end
end
