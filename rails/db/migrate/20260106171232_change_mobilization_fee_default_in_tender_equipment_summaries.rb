class ChangeMobilizationFeeDefaultInTenderEquipmentSummaries < ActiveRecord::Migration[7.2]
  def up
    change_column_default :tender_equipment_summaries, :mobilization_fee, from: 15000.0, to: 0.0
    
    # Update existing records to 0.0 and recalculate totals
    TenderEquipmentSummary.update_all(mobilization_fee: 0.0)
    TenderEquipmentSummary.find_each(&:calculate!)
  end

  def down
    change_column_default :tender_equipment_summaries, :mobilization_fee, from: 0.0, to: 15000.0
  end
end
