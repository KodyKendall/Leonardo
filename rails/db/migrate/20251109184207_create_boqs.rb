class CreateBoqs < ActiveRecord::Migration[7.2]
  def change
    create_table :boqs do |t|
      t.string :boq_name, null: false
      t.string :file_name, null: false
      t.string :file_path
      t.string :status, default: "uploaded", null: false
      t.string :client_name
      t.string :client_reference
      t.string :qs_name
      t.text :notes
      t.date :received_date
      t.bigint :uploaded_by_id
      t.datetime :parsed_at

      t.timestamps
    end

    add_index :boqs, :status
    add_index :boqs, :uploaded_by_id
    add_foreign_key :boqs, :users, column: :uploaded_by_id
  end
end
