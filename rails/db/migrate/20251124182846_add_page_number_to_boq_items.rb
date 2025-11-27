class AddPageNumberToBoqItems < ActiveRecord::Migration[7.2]
  def change
    add_column :boq_items, :page_number, :integer
  end
end
