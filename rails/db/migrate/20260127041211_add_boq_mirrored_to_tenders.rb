class AddBoqMirroredToTenders < ActiveRecord::Migration[7.2]
  def change
    add_column :tenders, :boq_mirrored, :boolean, default: false, null: false
  end
end
