class AddQobFileToTenders < ActiveRecord::Migration[7.2]
  def change
    add_column :tenders, :qob_file, :string
  end
end
