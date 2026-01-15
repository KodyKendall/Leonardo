class AddFinancialTonnageToTenders < ActiveRecord::Migration[7.2]
  def change
    add_column :tenders, :financial_tonnage, :decimal, precision: 12, scale: 3
  end
end
