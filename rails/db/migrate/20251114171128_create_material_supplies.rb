class CreateMaterialSupplies < ActiveRecord::Migration[7.2]
  def change
    create_table :material_supplies do |t|
      t.string :name
      t.decimal :waste_percentage

      t.timestamps
    end
  end
end
