class CreateTenderInclusionsExclusions < ActiveRecord::Migration[7.2]
  def change
    create_table :tender_inclusions_exclusions do |t|
      t.references :tender, null: false, foreign_key: true
      t.boolean :fabrication_included
      t.boolean :overheads_included
      t.boolean :primer_included
      t.boolean :final_paint_included
      t.boolean :delivery_included
      t.boolean :bolts_included
      t.boolean :erection_included
      t.boolean :crainage_included
      t.boolean :cherry_pickers_included
      t.boolean :steel_galvanized

      t.timestamps
    end
  end
end
