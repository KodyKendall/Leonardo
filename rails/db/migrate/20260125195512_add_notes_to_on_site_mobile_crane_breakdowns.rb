class AddNotesToOnSiteMobileCraneBreakdowns < ActiveRecord::Migration[7.2]
  def change
    add_column :on_site_mobile_crane_breakdowns, :notes, :text
  end
end
