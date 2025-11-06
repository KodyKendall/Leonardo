class CreateBudgetCategories < ActiveRecord::Migration[7.2]
  def change
    create_table :budget_categories do |t|
      t.string :category_name, null: false
      t.string :cost_code
      t.text :description

      t.timestamps
    end

    add_index :budget_categories, :category_name, unique: true
    add_index :budget_categories, :cost_code
  end
end
