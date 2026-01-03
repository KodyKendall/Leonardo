class AddNotesToTenderEquipmentSummaries < ActiveRecord::Migration[7.2]
  def change
    add_column :tender_equipment_summaries, :notes, :text
  end
end
