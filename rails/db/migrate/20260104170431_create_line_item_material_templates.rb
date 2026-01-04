class CreateLineItemMaterialTemplates < ActiveRecord::Migration[7.2]
  def change
    create_table :line_item_material_templates do |t|
      t.references :section_category_template, null: false, foreign_key: true
      t.references :material_supply, null: true, foreign_key: true
      t.decimal :proportion_percentage
      t.decimal :waste_percentage
      t.integer :sort_order

      t.timestamps
    end
  end
end
