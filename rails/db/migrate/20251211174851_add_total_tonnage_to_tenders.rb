class AddTotalTonnageToTenders < ActiveRecord::Migration[7.2]
  def change
    add_column :tenders, :total_tonnage, :decimal, precision: 12, scale: 3, default: 0.0
  end
end
