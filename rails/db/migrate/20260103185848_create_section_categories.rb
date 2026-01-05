class CreateSectionCategories < ActiveRecord::Migration[7.2]
  def change
    create_table :section_categories do |t|
      t.string :name, null: false
      t.string :display_name

      t.timestamps
    end
    add_index :section_categories, :name, unique: true
  end
end
