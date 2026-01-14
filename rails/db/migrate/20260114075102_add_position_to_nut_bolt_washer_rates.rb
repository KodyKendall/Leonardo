class AddPositionToNutBoltWasherRates < ActiveRecord::Migration[7.2]
  def change
    add_column :nut_bolt_washer_rates, :position, :integer, default: 0, null: false

    reversible do |dir|
      dir.up do
        NutBoltWasherRate.all.each_with_index do |rate, index|
          rate.update_column(:position, index + 1)
        end
      end
    end
  end
end
