class AddDefaultsToReportDisplayModes < ActiveRecord::Migration[7.2]
  def change
    change_column_default :tenders, :p_and_g_display_mode, from: nil, to: 'detailed'
    change_column_default :tenders, :shop_drawings_display_mode, from: nil, to: 'lump_sum'
    
    # Backfill existing records
    Tender.update_all(p_and_g_display_mode: 'detailed', shop_drawings_display_mode: 'lump_sum')
  end
end
