class CreateContactSubmissions < ActiveRecord::Migration[7.2]
  def change
    create_table :contact_submissions do |t|
      t.string :company_name, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :title, null: false
      t.string :email, null: false

      t.timestamps
    end
  end
end
