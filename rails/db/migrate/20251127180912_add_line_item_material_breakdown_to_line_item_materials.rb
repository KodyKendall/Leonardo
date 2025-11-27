class AddLineItemMaterialBreakdownToLineItemMaterials < ActiveRecord::Migration[7.2]
  def change
    add_reference :line_item_materials, :line_item_material_breakdown, null: true, foreign_key: true
    
    # Create a breakdown for each unique tender_line_item that has materials
    reversible do |dir|
      dir.up do
        execute <<-SQL
          INSERT INTO line_item_material_breakdowns (tender_line_item_id, created_at, updated_at)
          SELECT DISTINCT tender_line_item_id, NOW(), NOW()
          FROM line_item_materials
          ON CONFLICT DO NOTHING
        SQL
        
        execute <<-SQL
          UPDATE line_item_materials lim
          SET line_item_material_breakdown_id = (
            SELECT id FROM line_item_material_breakdowns limb
            WHERE limb.tender_line_item_id = lim.tender_line_item_id
            LIMIT 1
          )
          WHERE lim.line_item_material_breakdown_id IS NULL
        SQL
      end
    end
    
    # Make the column not null after data is populated
    change_column_null :line_item_materials, :line_item_material_breakdown_id, false
  end
end
