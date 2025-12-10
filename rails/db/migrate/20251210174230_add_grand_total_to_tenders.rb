class AddGrandTotalToTenders < ActiveRecord::Migration[7.2]
  def change
    add_column :tenders, :grand_total, :decimal, precision: 12, scale: 2, default: 0.0
  end
end
