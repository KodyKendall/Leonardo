class CreateVariationOrders < ActiveRecord::Migration[7.2]
  def change
    create_table :variation_orders do |t|
      t.string :vo_number, null: false
      t.references :project, foreign_key: true, null: false
      t.string :vo_status, default: "draft", null: false
      t.decimal :vo_amount, precision: 12, scale: 2, null: false
      t.text :description
      t.bigint :created_by_id
      t.bigint :approved_by_id
      t.text :approver_notes
      t.datetime :approved_at

      t.timestamps
    end

    add_index :variation_orders, :vo_number, unique: true
    add_index :variation_orders, [:project_id, :vo_status]
    add_index :variation_orders, :created_by_id
    add_index :variation_orders, :approved_by_id
    add_foreign_key :variation_orders, :users, column: :created_by_id
    add_foreign_key :variation_orders, :users, column: :approved_by_id
  end
end
