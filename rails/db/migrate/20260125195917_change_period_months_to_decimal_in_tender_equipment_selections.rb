class ChangePeriodMonthsToDecimalInTenderEquipmentSelections < ActiveRecord::Migration[7.2]
  def change
    change_column :tender_equipment_selections, :period_months, :decimal, precision: 10, scale: 2, default: 1.0, null: false
  end
end
