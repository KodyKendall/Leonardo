class AddOnSiteMobileCraneBreakdownIdToTenderCraneSelections < ActiveRecord::Migration[7.2]
  def change
    add_reference :tender_crane_selections, :on_site_mobile_crane_breakdown, null: true, foreign_key: true
  end
end
