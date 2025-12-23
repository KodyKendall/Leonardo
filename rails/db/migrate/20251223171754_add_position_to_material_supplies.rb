class AddPositionToMaterialSupplies < ActiveRecord::Migration[7.2]
  def change
    add_column :material_supplies, :position, :integer, default: 0, null: false
  end
end
