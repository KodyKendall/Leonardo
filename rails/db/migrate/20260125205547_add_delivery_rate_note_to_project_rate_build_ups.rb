class AddDeliveryRateNoteToProjectRateBuildUps < ActiveRecord::Migration[7.2]
  def change
    add_column :project_rate_build_ups, :delivery_rate_note, :string
  end
end
