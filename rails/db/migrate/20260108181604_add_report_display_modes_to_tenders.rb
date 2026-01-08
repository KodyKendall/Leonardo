class AddReportDisplayModesToTenders < ActiveRecord::Migration[7.2]
  def change
    add_column :tenders, :p_and_g_display_mode, :string
    add_column :tenders, :shop_drawings_display_mode, :string
  end
end
