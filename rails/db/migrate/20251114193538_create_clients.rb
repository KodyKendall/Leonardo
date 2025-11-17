class CreateClients < ActiveRecord::Migration[7.2]
  def change
    create_table :clients do |t|
      t.string :business_name
      t.string :contact_name
      t.string :contact_email

      t.timestamps
    end
  end
end
