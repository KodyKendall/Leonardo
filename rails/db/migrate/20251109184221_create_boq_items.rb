class CreateBoqItems < ActiveRecord::Migration[7.2]
  def change
    create_table :boq_items do |t|
      t.bigint :boq_id, null: false
      t.string :item_number
      t.text :item_description
      t.string :unit_of_measure
      t.decimal :quantity, precision: 10, scale: 3, default: 0
      t.string :section_category
      t.integer :sequence_order
      t.text :notes

      t.timestamps
    end

    add_index :boq_items, :boq_id
    add_foreign_key :boq_items, :boqs
  end
end
