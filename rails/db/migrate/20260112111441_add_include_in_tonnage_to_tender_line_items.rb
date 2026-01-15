class AddIncludeInTonnageToTenderLineItems < ActiveRecord::Migration[7.2]
  def change
    add_column :tender_line_items, :include_in_tonnage, :boolean, default: true, null: false
    
    # Backfill existing records
    reversible do |dir|
      dir.up do
        TenderLineItem.update_all(include_in_tonnage: true)
      end
    end
  end
end
