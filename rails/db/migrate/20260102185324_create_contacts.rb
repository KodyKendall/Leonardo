class CreateContacts < ActiveRecord::Migration[7.2]
  def change
    create_table :contacts do |t|
      t.string :name
      t.string :email
      t.string :phone
      t.boolean :is_primary, default: false, null: false
      t.references :client, null: false, foreign_key: true

      t.timestamps
    end

    reversible do |dir|
      dir.up do
        Client.find_each do |client|
          if client.contact_name.present? || client.contact_email.present?
            Contact.create!(
              client_id: client.id,
              name: client.contact_name,
              email: client.contact_email,
              is_primary: true
            )
          end
        end
      end
    end
  end
end
