class CreatePreliminariesGeneralItems < ActiveRecord::Migration[7.2]
  def change
    create_table :preliminaries_general_items do |t|
      t.references :tender, null: false, foreign_key: true
      t.string :category, null: false
      t.text :description
      t.decimal :quantity, precision: 10, scale: 3, default: 0
      t.decimal :rate, precision: 12, scale: 2, default: 0
      t.integer :sort_order, default: 0

      t.timestamps
    end
  end
end
