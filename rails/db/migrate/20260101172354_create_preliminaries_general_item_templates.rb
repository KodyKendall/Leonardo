class CreatePreliminariesGeneralItemTemplates < ActiveRecord::Migration[7.2]
  def change
    create_table :preliminaries_general_item_templates do |t|
      t.string :category
      t.text :description
      t.decimal :quantity, precision: 10, scale: 3
      t.decimal :rate, precision: 12, scale: 2
      t.integer :sort_order
      t.boolean :is_crane, default: false, null: false
      t.boolean :is_access_equipment, default: false, null: false

      t.timestamps
    end
  end
end
