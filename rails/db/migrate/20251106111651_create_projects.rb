class CreateProjects < ActiveRecord::Migration[7.2]
  def change
    create_table :projects do |t|
      t.string :rsb_number, null: false
      t.references :tender, foreign_key: true, null: false
      t.string :project_status, default: "active", null: false
      t.date :project_start_date
      t.date :project_end_date
      t.decimal :budget_total, precision: 12, scale: 2
      t.decimal :actual_spend, precision: 12, scale: 2, default: 0
      t.bigint :created_by_id

      t.timestamps
    end

    add_index :projects, :rsb_number, unique: true
    add_index :projects, :project_status
    add_index :projects, :created_by_id
    add_foreign_key :projects, :users, column: :created_by_id
  end
end
