class CreateTenders < ActiveRecord::Migration[7.2]
  def change
    create_table :tenders do |t|
      t.string :e_number, null: false
      t.string :status, default: "draft", null: false
      t.string :client_name
      t.decimal :tender_value, precision: 12, scale: 2
      t.string :project_type, default: "commercial"
      t.text :notes
      t.bigint :awarded_project_id

      t.timestamps
    end

    add_index :tenders, :e_number, unique: true
    add_index :tenders, :status
    add_index :tenders, :awarded_project_id
  end
end
