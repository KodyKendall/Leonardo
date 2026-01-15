class AddPositionToAnchorRates < ActiveRecord::Migration[7.2]
  def change
    add_column :anchor_rates, :position, :integer
    add_index :anchor_rates, :position

    # Initialize positions for existing records
    reversible do |dir|
      dir.up do
        AnchorRate.order(:created_at).each_with_index do |rate, index|
          rate.update_column(:position, index + 1)
        end
      end
    end
  end
end
