class ChangePageNumberTypeInBoqItems < ActiveRecord::Migration[7.2]
  def change
    change_column :boq_items, :page_number, :text
  end
end
