class CreateProjectRateBuildUps < ActiveRecord::Migration[7.2]
  def change
    create_table :project_rate_build_ups do |t|
      t.references :tender, null: false, foreign_key: true
      t.decimal :material_supply_rate
      t.decimal :fabrication_rate
      t.decimal :overheads_rate
      t.decimal :shop_priming_rate
      t.decimal :onsite_painting_rate
      t.decimal :delivery_rate
      t.decimal :bolts_rate
      t.decimal :erection_rate
      t.decimal :crainage_rate
      t.decimal :cherry_picker_rate
      t.decimal :galvanizing_rate

      t.timestamps
    end
  end
end
