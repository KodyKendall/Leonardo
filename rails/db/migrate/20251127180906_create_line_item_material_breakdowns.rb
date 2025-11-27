class CreateLineItemMaterialBreakdowns < ActiveRecord::Migration[7.2]
  def change
    create_table :line_item_material_breakdowns do |t|
      t.references :tender_line_item, null: false, foreign_key: true

      t.timestamps
    end
  end
end
