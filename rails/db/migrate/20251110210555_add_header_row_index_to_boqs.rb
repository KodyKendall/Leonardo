class AddHeaderRowIndexToBoqs < ActiveRecord::Migration[7.2]
  def change
    add_column :boqs, :header_row_index, :integer, default: 0
  end
end
