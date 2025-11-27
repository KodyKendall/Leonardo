class AddFieldsToTenders < ActiveRecord::Migration[7.2]
  def change
    add_column :tenders, :tender_name, :string
    add_column :tenders, :client_id, :bigint
    add_column :tenders, :submission_deadline, :date
    add_foreign_key :tenders, :clients, column: :client_id
    add_index :tenders, :client_id
  end
end
