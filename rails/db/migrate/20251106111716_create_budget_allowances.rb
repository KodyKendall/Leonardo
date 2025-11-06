class CreateBudgetAllowances < ActiveRecord::Migration[7.2]
  def change
    create_table :budget_allowances do |t|
      t.references :project, foreign_key: true, null: false
      t.references :budget_category, foreign_key: true, null: false
      t.decimal :budgeted_amount, precision: 12, scale: 2, default: 0
      t.decimal :actual_spend, precision: 12, scale: 2, default: 0
      t.decimal :variance, precision: 12, scale: 2, default: 0

      t.timestamps
    end

    add_index :budget_allowances, [:project_id, :budget_category_id], unique: true
  end
end
