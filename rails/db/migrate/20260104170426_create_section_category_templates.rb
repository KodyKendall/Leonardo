class CreateSectionCategoryTemplates < ActiveRecord::Migration[7.2]
  def change
    create_table :section_category_templates do |t|
      t.references :section_category, null: false, foreign_key: true

      t.timestamps
    end
  end
end
